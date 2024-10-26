import Foundation
import SourceKittenFramework

private let moduleToLog = ProcessInfo.processInfo.environment["SWIFTLINT_LOG_MODULE_USAGE"]

struct UnusedImportRule: CorrectableRule, AnalyzerRule {
    var configuration = UnusedImportConfiguration()

    static let description = RuleDescription(
        identifier: "unused_import",
        name: "Unused Import",
        description: "All imported modules should be required to make the file compile",
        kind: .lint,
        nonTriggeringExamples: UnusedImportRuleExamples.nonTriggeringExamples,
        triggeringExamples: UnusedImportRuleExamples.triggeringExamples,
        corrections: UnusedImportRuleExamples.corrections,
        requiresFileOnDisk: true
    )

    func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        importUsage(in: file, compilerArguments: compilerArguments).map { importUsage in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: importUsage.violationRange?.location ?? 1),
                           reason: importUsage.violationReason)
        }
    }

    func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        let importUsages = importUsage(in: file, compilerArguments: compilerArguments)
        let matches = file.ruleEnabled(violatingRanges: importUsages.compactMap(\.violationRange), for: self)

        var contents = file.stringView.nsString
        let description = Self.description
        var corrections = [Correction]()
        for range in matches.reversed() {
            contents = contents.replacingCharacters(in: range, with: "").bridge()
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        if corrections.isNotEmpty {
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

        guard missingImports.isNotEmpty else {
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
        guard compilerArguments.isNotEmpty else {
            Issue.missingCompilerArguments(path: file.path, ruleID: Self.identifier).print()
            return []
        }

        return file.getImportUsage(compilerArguments: compilerArguments, configuration: configuration)
    }
}

private extension SwiftLintFile {
    func getImportUsage(compilerArguments: [String], configuration: UnusedImportConfiguration) -> [ImportUsage] {
        var (imports, usrFragments) = getImportsAndUSRFragments(compilerArguments: compilerArguments)

        // Always disallow 'Swift' and 'SwiftShims' because they're always available without importing.
        usrFragments.remove("Swift")
        usrFragments.remove("SwiftShims")
        if SwiftVersion.current >= .fiveDotSix {
            usrFragments.remove("main")
        }

        var unusedImports = imports.subtracting(usrFragments).subtracting(configuration.alwaysKeepImports)
        // Certain Swift attributes requires importing Foundation.
        if unusedImports.contains("Foundation") && containsAttributesRequiringFoundation() {
            unusedImports.remove("Foundation")
        }

        if unusedImports.isNotEmpty {
            unusedImports.subtract(
                operatorImports(
                    arguments: compilerArguments,
                    processedTokenOffsets: Set(syntaxMap.tokens.map(\.offset))
                )
            )
        }

        // Find the missing imports, which should be imported, but are not.
        let currentModule = (compilerArguments.firstIndex(of: "-module-name")?.advanced(by: 1))
            .map { compilerArguments[$0] }

        var missingImports = usrFragments
            .subtracting(imports + [currentModule].compactMap({ $0 }))
            .filter { module in
                let modulesAllowedToImportCurrentModule = configuration.allowedTransitiveImports
                    .filter { !unusedImports.contains($0.importedModule) }
                    .filter { $0.transitivelyImportedModules.contains(module) }
                    .map(\.importedModule)

                return modulesAllowedToImportCurrentModule.isEmpty ||
                    imports.isDisjoint(with: modulesAllowedToImportCurrentModule)
            }

        // Check if unused imports were used for transitive imports
        var foundUmbrellaModules = Set<String>()
        var foundMissingImports = Set<String>()
        for missingImport in missingImports {
            let umbrellaModules = configuration.allowedTransitiveImports
                .filter { $0.transitivelyImportedModules.contains(missingImport) }
                .map(\.importedModule)
            if umbrellaModules.isEmpty {
                continue
            }
            foundMissingImports.insert(missingImport)
            foundUmbrellaModules.formUnion(umbrellaModules.filter(unusedImports.contains))
        }

        unusedImports.subtract(foundUmbrellaModules)
        missingImports.subtract(foundMissingImports)

        let unusedImportUsages = rangedAndSortedUnusedImports(of: Array(unusedImports))
            .map { ImportUsage.unused(module: $0, range: $1) }

        return configuration.requireExplicitImports
            ? unusedImportUsages + missingImports.sorted().map { .missing(module: $0) }
            : unusedImportUsages
    }

    func getImportsAndUSRFragments(compilerArguments: [String]) -> (imports: Set<String>, usrFragments: Set<String>) {
        var imports = Set<String>()
        var usrFragments = Set<String>()
        var nextIsModuleImport = false
        for token in syntaxMap.tokens {
            guard let tokenKind = token.kind else {
                continue
            }
            if tokenKind == .keyword, contents(for: token) == "import" {
                nextIsModuleImport = true
                continue
            }
            if SyntaxKind.kindsWithoutModuleInfo.contains(tokenKind) {
                continue
            }
            let cursorInfoRequest = Request.cursorInfoWithoutSymbolGraph(
                file: path!, offset: token.offset, arguments: compilerArguments
            )
            guard let cursorInfo = (try? cursorInfoRequest.sendIfNotDisabled()).map(SourceKittenDictionary.init) else {
                Issue.missingCursorInfo(path: path, ruleID: UnusedImportRule.identifier).print()
                continue
            }
            if nextIsModuleImport {
                nextIsModuleImport = false
                if let importedModule = cursorInfo.moduleName,
                    cursorInfo.kind == "source.lang.swift.ref.module" {
                    imports.insert(importedModule)
                    continue
                }
            }

            appendUsedImports(cursorInfo: cursorInfo, usrFragments: &usrFragments)

            // also collect modules from secondary symbol usage if available
            for secondaryInfo in cursorInfo.secondarySymbols {
                appendUsedImports(cursorInfo: secondaryInfo, usrFragments: &usrFragments)
            }
        }

        return (imports: imports, usrFragments: usrFragments)
    }

    func rangedAndSortedUnusedImports(of unusedImports: [String]) -> [(String, NSRange)] {
        unusedImports
            .compactMap { module in
                match(pattern: "^(@(?!_exported)\\w+ +)?import +\(module)\\b.*?\n").first.map { (module, $0.0) }
            }
            .sorted(by: { $0.1.location < $1.1.location })
    }

    // Operators are omitted in the editor.open request and thus have to be looked up by the indexsource request
    func operatorImports(arguments: [String], processedTokenOffsets: Set<ByteCount>) -> Set<String> {
        guard let index = (try? Request.index(file: path!, arguments: arguments).sendIfNotDisabled())
            .map(SourceKittenDictionary.init) else {
            Issue.indexingError(path: path, ruleID: UnusedImportRule.identifier).print()
            return []
        }

        let operatorEntities = flatEntities(entity: index).filter { mightBeOperator(kind: $0.kind) }
        let offsetPerLine = self.offsetPerLine()
        var imports = Set<String>()

        for entity in operatorEntities {
            if
                let line = entity.line,
                let column = entity.column,
                let lineOffset = offsetPerLine[Int(line) - 1] {
                let offset = lineOffset + column - 1

                // Filter already processed tokens such as static methods that are not operators
                guard !processedTokenOffsets.contains(ByteCount(offset)) else { continue }

                let cursorInfoRequest = Request.cursorInfoWithoutSymbolGraph(
                    file: path!, offset: ByteCount(offset), arguments: arguments
                )
                guard let cursorInfo = (try? cursorInfoRequest.sendIfNotDisabled())
                    .map(SourceKittenDictionary.init) else {
                    Issue.missingCursorInfo(path: path, ruleID: UnusedImportRule.identifier).print()
                    continue
                }

                appendUsedImports(cursorInfo: cursorInfo, usrFragments: &imports)
            }
        }

        return imports
    }

    func flatEntities(entity: SourceKittenDictionary) -> [SourceKittenDictionary] {
        let entities = entity.entities
        if entities.isEmpty {
            return [entity]
        }
        return [entity] + entities.flatMap { flatEntities(entity: $0) }
    }

    func offsetPerLine() -> [Int: Int64] {
        Dictionary(
            uniqueKeysWithValues: contents.bridge()
                .components(separatedBy: "\n")
                .map { Int64($0.bridge().lengthOfBytes(using: .utf8)) }
                .reduce(into: [0]) { result, length in
                    let newLineCharacterLength = Int64(1)
                    let lineLength = length + newLineCharacterLength
                    result.append(contentsOf: [(result.last ?? 0) + lineLength])
                }
                .enumerated()
                .map { ($0.offset, $0.element) }
        )
    }

    // Operators that are a part of some body are reported as method.static
    func mightBeOperator(kind: String?) -> Bool {
        guard let kind else { return false }
        return [
            "source.lang.swift.ref.function.operator",
            "source.lang.swift.ref.function.method.static",
        ].contains { kind.hasPrefix($0) }
    }

    func appendUsedImports(cursorInfo: SourceKittenDictionary, usrFragments: inout Set<String>) {
        if let rootModuleName = cursorInfo.moduleName?.split(separator: ".").first.map(String.init) {
            usrFragments.insert(rootModuleName)
            if rootModuleName == moduleToLog, let filePath = path, let usr = cursorInfo.value["key.usr"] as? String {
                queuedPrintError(
                    "[SWIFTLINT_LOG_MODULE_USAGE] \(rootModuleName) referenced by USR '\(usr)' in file '\(filePath)'"
                )
            }
        }
    }

    /// Returns whether or not the file contains any attributes that require the Foundation module.
    func containsAttributesRequiringFoundation() -> Bool {
        guard contents.contains("@objc") else {
            return false
        }

        func containsAttributesRequiringFoundation(dict: SourceKittenDictionary) -> Bool {
            let attributesRequiringFoundation = SwiftDeclarationAttributeKind.attributesRequiringFoundation
            if !attributesRequiringFoundation.isDisjoint(with: dict.enclosedSwiftAttributes) {
                return true
            }
            return dict.substructure.contains(where: containsAttributesRequiringFoundation)
        }

        return containsAttributesRequiringFoundation(dict: structureDictionary)
    }
}
