import Foundation
import SourceKittenFramework

public struct UnusedImportRule: CorrectableRule, ConfigurationProviderRule, AnalyzerRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_import",
        name: "Unused Import",
        description: "All imported modules should be required to make the file compile.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            import Dispatch // This is used
            dispatchMain()
            """),
            Example("""
            @testable import Dispatch
            dispatchMain()
            """),
            Example("""
            import Foundation
            @objc
            class A {}
            """),
            Example("""
            import UnknownModule
            func foo(error: Swift.Error) {}
            """),
            Example("""
            import Foundation
            import ObjectiveC
            let 👨‍👩‍👧‍👦 = #selector(NSArray.contains(_:))
            👨‍👩‍👧‍👦 == 👨‍👩‍👧‍👦
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓import Dispatch
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """),
            Example("""
            ↓import Foundation // This is unused
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            ↓import Dispatch

            """),
            Example("""
            ↓import Foundation
            dispatchMain()
            """),
            Example("""
            ↓import Foundation
            // @objc
            class A {}
            """),
            Example("""
            ↓import Foundation
            import UnknownModule
            func foo(error: Swift.Error) {}
            """)
        ],
        corrections: [
            Example("""
            ↓import Dispatch
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """): Example("""
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """),
            Example("""
            ↓import Foundation // This is unused
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            ↓import Dispatch

            """): Example("""
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()

            """),
            Example("""
            ↓import Foundation
            dispatchMain()
            """): Example("""
            dispatchMain()
            """),
            Example("""
            ↓@testable import Foundation
            import Dispatch
            dispatchMain()
            """): Example("""
            import Dispatch
            dispatchMain()
            """),
            Example("""
            ↓@_exported import Foundation
            import Dispatch
            dispatchMain()
            """): Example("""
            import Dispatch
            dispatchMain()
            """),
            Example("""
            ↓import Foundation
            // @objc
            class A {}
            """): Example("""
            // @objc
            class A {}
            """),
            Example("""
            @testable import Foundation
            ↓import Dispatch
            @objc
            class A {}
            """): Example("""
            @testable import Foundation
            @objc
            class A {}
            """),
            Example("""
            @testable import Foundation
            ↓@testable import Dispatch
            @objc
            class A {}
            """):
            Example("""
            @testable import Foundation
            @objc
            class A {}
            """)
        ],
        requiresFileOnDisk: true
    )

    public func validate(file: SwiftLintFile, compilerArguments: [String]) -> [StyleViolation] {
        return violationRanges(in: file, compilerArguments: compilerArguments).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: SwiftLintFile, compilerArguments: [String]) -> [Correction] {
        let violations = violationRanges(in: file, compilerArguments: compilerArguments)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        var contents = file.contents.bridge()
        let description = type(of: self).description
        var corrections = [Correction]()
        for range in matches.reversed() {
            contents = contents.replacingCharacters(in: range, with: "").bridge()
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents.bridge())
        return corrections
    }

    private func violationRanges(in file: SwiftLintFile, compilerArguments: [String]) -> [NSRange] {
        guard !compilerArguments.isEmpty else {
            queuedPrintError("""
                Attempted to lint file at path '\(file.path ?? "...")' with the \
                \(type(of: self).description.identifier) rule without any compiler arguments.
                """)
            return []
        }

        return file.unusedImports(compilerArguments: compilerArguments).map { $0.1 }
    }
}

private extension SwiftLintFile {
    func unusedImports(compilerArguments: [String]) -> [(String, NSRange)] {
        let contentsNSString = contents.bridge()
        var imports = Set<String>()
        var usrFragments = Set<String>()
        var nextIsModuleImport = false
        let tokens = syntaxMap.tokens
        for token in tokens {
            guard let tokenKind = token.kind else {
                continue
            }
            if tokenKind == .keyword, contents(for: token) == "import" {
                nextIsModuleImport = true
                continue
            }
            if syntaxKindsToSkip.contains(tokenKind) {
                continue
            }
            let cursorInfoRequest = Request.cursorInfo(file: path!, offset: token.offset,
                                                       arguments: compilerArguments)
            guard let cursorInfo = (try? cursorInfoRequest.sendIfNotDisabled()).map(SourceKittenDictionary.init) else {
                queuedPrintError("Could not get cursor info")
                continue
            }
            if nextIsModuleImport {
                if let importedModule = cursorInfo.moduleName,
                    cursorInfo.kind == "source.lang.swift.ref.module" {
                    imports.insert(importedModule)
                    nextIsModuleImport = false
                    continue
                } else {
                    nextIsModuleImport = false
                }
            }

            appendUsedImports(cursorInfo: cursorInfo, usrFragments: &usrFragments)
        }

        // Always disallow 'import Swift' because it's available without importing.
        usrFragments.remove("Swift")
        var unusedImports = imports.subtracting(usrFragments)
        // Certain Swift attributes requires importing Foundation.
        if unusedImports.contains("Foundation") && containsAttributesRequiringFoundation() {
            unusedImports.remove("Foundation")
        }

        if !unusedImports.isEmpty {
            unusedImports.subtract(
                operatorImports(
                    arguments: compilerArguments,
                    processedTokenOffsets: Set(tokens.map { $0.offset })
                )
            )
        }

        return rangedAndSortedUnusedImports(of: Array(unusedImports), contents: contentsNSString)
    }

    func rangedAndSortedUnusedImports(of unusedImports: [String], contents: NSString) -> [(String, NSRange)] {
        return unusedImports
            .compactMap { module in
                self.match(pattern: "^(@[\\w_]+ +)?import +\(module)\\b.*?\n").first.map { (module, $0.0) }
            }
            .sorted(by: { $0.1.location < $1.1.location })
    }

    // Operators are omitted in the editor.open request and thus have to be looked up by the indexsource request
    func operatorImports(arguments: [String], processedTokenOffsets: Set<ByteCount>) -> Set<String> {
        guard let index = (try? Request.index(file: path!, arguments: arguments).sendIfNotDisabled())
            .map(SourceKittenDictionary.init) else {
            queuedPrintError("Could not get index")
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

                let cursorInfoRequest = Request.cursorInfo(file: path!, offset: ByteCount(offset), arguments: arguments)
                guard let cursorInfo = (try? cursorInfoRequest.sendIfNotDisabled())
                    .map(SourceKittenDictionary.init) else {
                    queuedPrintError("Could not get cursor info")
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
        } else {
            return [entity] + entities.flatMap { flatEntities(entity: $0) }
        }
    }

    func offsetPerLine() -> [Int: Int64] {
        return Dictionary(
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
        guard let kind = kind else { return false }
        return [
            "source.lang.swift.ref.function.operator",
            "source.lang.swift.ref.function.method.static"
        ].contains { kind.hasPrefix($0) }
    }

    func appendUsedImports(cursorInfo: SourceKittenDictionary, usrFragments: inout Set<String>) {
        if let usr = cursorInfo.moduleName {
            usrFragments.formUnion(usr.split(separator: ".").map(String.init))
        }
    }

    func containsAttributesRequiringFoundation() -> Bool {
        guard contents.contains("@objc") else {
            return false
        }

        func containsAttributesRequiringFoundation(dict: SourceKittenDictionary) -> Bool {
            if !attributesRequiringFoundation.isDisjoint(with: dict.enclosedSwiftAttributes) {
                return true
            } else {
                return dict.substructure.contains(where: containsAttributesRequiringFoundation)
            }
        }

        return containsAttributesRequiringFoundation(dict: self.structureDictionary)
    }
}

private extension SourceKittenDictionary {
    /// Module name in @import expressions
    var moduleName: String? {
        return value["key.modulename"] as? String
    }

    var line: Int64? {
        return value["key.line"] as? Int64
    }

    var column: Int64? {
        return value["key.column"] as? Int64
    }
}

private let syntaxKindsToSkip: Set<SyntaxKind> = [
    .attributeBuiltin,
    .keyword,
    .number,
    .docComment,
    .string,
    .stringInterpolationAnchor,
    .attributeID,
    .buildconfigKeyword,
    .buildconfigID,
    .commentURL,
    .comment,
    .docCommentField
]

private let attributesRequiringFoundation: Set<SwiftDeclarationAttributeKind> = [
    .objc,
    .objcName,
    .objcMembers,
    .objcNonLazyRealization
]
