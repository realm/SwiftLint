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
            """
            import Dispatch
            dispatchMain()
            """,
            """
            @testable import Dispatch
            dispatchMain()
            """,
            """
            import Foundation
            @objc
            class A {}
            """
        ],
        triggeringExamples: [
            """
            ↓import Dispatch
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """,
            """
            ↓import Foundation
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            ↓import Dispatch

            """,
            """
            ↓import Foundation
            dispatchMain()
            """,
            """
            ↓import Foundation
            // @objc
            class A {}
            """
        ],
        corrections: [
            """
            ↓import Dispatch
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """:
            """
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            """,
            """
            ↓import Foundation
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()
            ↓import Dispatch

            """:
            """
            struct A {
              static func dispatchMain() {}
            }
            A.dispatchMain()

            """,
            """
            ↓import Foundation
            dispatchMain()
            """:
            """
            dispatchMain()
            """,
            """
            ↓@testable import Foundation
            import Dispatch
            dispatchMain()
            """:
            """
            import Dispatch
            dispatchMain()
            """,
            """
            ↓import Foundation
            // @objc
            class A {}
            """:
            """
            // @objc
            class A {}
            """
        ],
        requiresFileOnDisk: true
    )

    public func validate(file: File, compilerArguments: [String]) -> [StyleViolation] {
        return violationRanges(in: file, compilerArguments: compilerArguments).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File, compilerArguments: [String]) -> [Correction] {
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

    private func violationRanges(in file: File, compilerArguments: [String]) -> [NSRange] {
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

private extension File {
    func unusedImports(compilerArguments: [String]) -> [(String, NSRange)] {
        let contentsNSString = contents.bridge()
        var imports = Set<String>()
        var usrFragments = Set<String>()
        var nextIsModuleImport = false
        for token in syntaxMap.tokens {
            guard let tokenKind = SyntaxKind(rawValue: token.type) else {
                continue
            }
            if tokenKind == .keyword,
                let substring = contentsNSString.substringWithByteRange(start: token.offset, length: token.length),
                substring == "import" {
                nextIsModuleImport = true
                continue
            }
            if syntaxKindsToSkip.contains(tokenKind) {
                continue
            }
            let cursorInfoRequest = Request.cursorInfo(file: path!, offset: Int64(token.offset),
                                                       arguments: compilerArguments)
            guard let cursorInfo = try? cursorInfoRequest.sendIfNotDisabled() else {
                queuedPrintError("Could not get cursor info")
                continue
            }
            if nextIsModuleImport {
                if let importedModule = cursorInfo["key.modulename"] as? String,
                    cursorInfo["key.kind"] as? String == "source.lang.swift.ref.module" {
                    imports.insert(importedModule)
                    nextIsModuleImport = false
                    continue
                }
            } else {
                nextIsModuleImport = false
            }

            if let usr = cursorInfo["key.modulename"] as? String {
                usrFragments.formUnion(usr.split(separator: ".").map(String.init))
            }
        }
        // Always disallow 'import Swift' because it's available without importing.
        usrFragments.remove("Swift")
        var unusedImports = imports.subtracting(usrFragments)
        // Certain Swift attributes requires importing Foundation.
        if unusedImports.contains("Foundation") && containsAttributesRequiringFoundation() {
            unusedImports.remove("Foundation")
        }
        return unusedImports
            .map { module in
                let testableImportRange = contentsNSString.range(of: "@testable import \(module)\n")
                if testableImportRange.location != NSNotFound {
                    return (module, testableImportRange)
                }

                return (module, contentsNSString.range(of: "import \(module)\n"))
            }
            .sorted(by: { $0.1.location < $1.1.location })
    }

    private func containsAttributesRequiringFoundation() -> Bool {
        guard contents.contains("@objc") else {
            return false
        }

        func containsAttributesRequiringFoundation(dict: [String: SourceKitRepresentable]) -> Bool {
            if !attributesRequiringFoundation.isDisjoint(with: dict.enclosedSwiftAttributes) {
                return true
            } else {
                return dict.substructure.contains(where: containsAttributesRequiringFoundation)
            }
        }

        return containsAttributesRequiringFoundation(dict: self.structure.dictionary)
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
