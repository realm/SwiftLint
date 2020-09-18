import Foundation
import SourceKittenFramework

public struct UnusedImportRule: CorrectableRule, ConfigurationProviderRule, AnalyzerRule, AutomaticTestableRule {
    public var configuration = UnusedImportConfiguration(severity: .warning, requireExplicitImports: false,
                                                         allowedTransitiveImports: [])

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_import",
        name: "Unused Import",
        description: "All imported modules should be required to make the file compile.",
        kind: .lint,
        nonTriggeringExamples: UnusedImportRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnusedImportRuleExamples.triggeringExamples,
        corrections: UnusedImportRuleExamples.corrections,
        requiresFileOnDisk: true
    )

    public func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        return importUsage(in: file, compilerArguments: compilerArguments).map { importUsage in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity.severity,
                           location: Location(file: file, characterOffset: importUsage.violationRange?.location ?? 1),
                           reason: importUsage.violationReason)
        }
    }

    public func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        let importUsages = importUsage(in: file, compilerArguments: compilerArguments)
        let matches = file.ruleEnabled(violatingRanges: importUsages.compactMap({ $0.violationRange }), for: self)

        var contents = file.stringView.nsString
        let description = Self.description
        var corrections = [Correction]()
        for range in matches.reversed() {
            contents = contents.replacingCharacters(in: range, with: "").bridge()
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        if !corrections.isEmpty {
            file.write(contents.bridge())
        }

        guard configuration.requireExplicitImports else {
            return corrections
        }

        let missingImports = importUsages.compactMap { importUsage -> String? in
            switch importUsage {
            case .unused:
                return nil
            case .missing(let module):
                return module
            }
        }

        guard !missingImports.isEmpty else {
            return corrections
        }

        var insertionLocation = 0
        if let firstImportRange = file.match(pattern: "import\\s+\\w+", with: [.keyword, .identifier]).first {
            contents.getLineStart(&insertionLocation, end: nil, contentsEnd: nil, for: firstImportRange)
        }

        let insertionRange = NSRange(location: insertionLocation, length: 0)
        let missingImportStatements = missingImports
            .sorted()
            .map { "import \($0)" }
            .joined(separator: "\n")
        let newContents = contents.replacingCharacters(in: insertionRange, with: missingImportStatements + "\n")
        file.write(newContents)
        let location = Location(file: file, characterOffset: 0)
        let missingImportCorrections = missingImports.map { _ in
            Correction(ruleDescription: description, location: location)
        }
        corrections.append(contentsOf: missingImportCorrections)
        // Attempt to sort imports
        corrections.append(contentsOf: SortedImportsRule().correct(file: file))
        return corrections
    }

    private func importUsage(in file: SwiftLintFile, compilerArguments: [String]) -> [ImportUsage] {
        guard !compilerArguments.isEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(Self.description.identifier) rule without any compiler arguments.
                """)
            return []
        }

        return file.getImportUsage(compilerArguments: compilerArguments, configuration: configuration)
    }
}

private extension SwiftLintFile {
    func getImportUsage(compilerArguments: [String], configuration: UnusedImportConfiguration) -> [ImportUsage] {
        guard let index = index(compilerArguments: compilerArguments) else {
            queuedPrintError("Could not get index")
            return []
        }

        var (imports, usrFragments) = getImportsAndUSRFragments(index: index, compilerArguments: compilerArguments)

        // Always disallow 'import Swift' because it's available without importing.
        usrFragments.remove("Swift")
        var unusedImports = imports.subtracting(usrFragments)
        // Certain Swift attributes requires importing Foundation.
        if unusedImports.contains("Foundation") && containsAttributesRequiringFoundation() {
            unusedImports.remove("Foundation")
        }

        let contentsNSString = stringView.nsString
        let unusedImportUsages = rangedAndSortedUnusedImports(of: Array(unusedImports), contents: contentsNSString)
            .map { ImportUsage.unused(module: $0, range: $1) }

        guard configuration.requireExplicitImports else {
            return unusedImportUsages
        }

        let currentModule = (compilerArguments.firstIndex(of: "-module-name")?.advanced(by: 1))
            .map { compilerArguments[$0] }

        let missingImports = usrFragments
            .subtracting(imports + [currentModule].compactMap({ $0 }))
            .filter { module in
                let modulesAllowedToImportCurrentModule = configuration.allowedTransitiveImports
                    .filter { !unusedImports.contains($0.importedModule) }
                    .filter { $0.transitivelyImportedModules.contains(module) }
                    .map { $0.importedModule }

                return modulesAllowedToImportCurrentModule.isEmpty ||
                    imports.isDisjoint(with: modulesAllowedToImportCurrentModule)
            }

        return unusedImportUsages + missingImports.sorted().map { .missing(module: $0) }
    }

    func getImportsAndUSRFragments(index: SourceKittenDictionary, compilerArguments: [String])
        -> (imports: Set<String>, usrFragments: Set<String>) {
        var usrFragments = Set<String>()

        let allEntities = flatEntities(entity: index)

        let referenceEntities = allEntities.filter { entity in
            entity.kind?.starts(with: "source.lang.swift.ref") == true &&
                entity.kind != "source.lang.swift.ref.module"
        }

        struct Reference {
            let line, column: Int
            let usr: String
        }

        let dedupedLineAndColumns = referenceEntities
            .compactMap { entity in
                entity.line.flatMap { line in
                    entity.column.flatMap { column in
                        entity.usr.map { usr in
                            Reference(line: Int(line), column: Int(column), usr: usr)
                        }
                    }
                }
            }
            // don't cursor-info the same USR at different locations
            .unique(by: { $0.usr })
            // don't cursor-info different USRs at the same location
            .unique(by: { [$0.line, $0.column] })
            .map { ($0.line, $0.column) }

        for (line, column) in dedupedLineAndColumns {
            let nameOffset = stringView.byteOffset(forLine: line, column: column)
            let cursorInfoRequest = Request.cursorInfo(file: path!, offset: nameOffset, arguments: compilerArguments)
            guard let cursorInfo = (try? cursorInfoRequest.sendIfNotDisabled()).map(SourceKittenDictionary.init) else {
                queuedPrintError("Could not get cursor info")
                continue
            }

            if let rootModuleName = cursorInfo.moduleName?.split(separator: ".").first.map(String.init) {
                usrFragments.insert(rootModuleName)
            }
        }

        let imports = index.dependencies?
            .filter { $0.kind?.starts(with: "source.lang.swift.import.module") == true }
            .compactMap { $0.name }
            .filter { $0 != "Swift" }

        return (imports: Set(imports ?? []), usrFragments: usrFragments)
    }

    func rangedAndSortedUnusedImports(of unusedImports: [String], contents: NSString) -> [(String, NSRange)] {
        return unusedImports
            .compactMap { module in
                match(pattern: "^(@\\w+ +)?import +\(module)\\b.*?\n").first.map { (module, $0.0) }
            }
            .sorted(by: { $0.1.location < $1.1.location })
    }

    func flatEntities(entity: SourceKittenDictionary) -> [SourceKittenDictionary] {
        let entities = entity.entities
        if entities.isEmpty {
            return [entity]
        } else {
            return [entity] + entities.flatMap { flatEntities(entity: $0) }
        }
    }
}
