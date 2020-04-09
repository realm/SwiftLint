import Foundation
import SourceKittenFramework

public struct MissingImportResultRule: Rule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "missing_import_result",
        name: "Missing Import Result",
        description: "You must add `import Result` in order to use the correct `Result` type.",
        kind: .lint,
        minSwiftVersion: .four,
        nonTriggeringExamples: [
            Example("""
            @testable import Foo
            import Foundation
            import Result
            func foo() -> Result<String, Error> { }
            func foo(result: Result<String, Error>) ->  {
                let r: Result<String> = result
            }
            func Result() {
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            @testable import Foo
            import Foundation
            func foo() -> ↓Result<String, Error> { }
            func foo(result: ↓Result<String, Error>) ->  {
                let r: ↓Result<String> = result
            }
            func Result() {
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.checkIfMissingImportResult().map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0))
        }
    }
}

extension SwiftLintFile {
    enum Keywords {
        static let IMPORT = "import"
        static let RESULT = "Result"
    }

    func checkIfMissingImportResult() -> [Int] {
        var nextTokenIsModuleName = false
        var resultTypeOffsets: [Int] = []
        let tokens = syntaxMap.tokens
        let stringView = file.stringView
        for token in tokens {
            guard let tokenKind = token.kind else {
                continue
            }
            if tokenKind == .keyword, let tokenText = contents(for: token), tokenText == Keywords.IMPORT {
                nextTokenIsModuleName = true
                continue
            }
            if nextTokenIsModuleName {
                nextTokenIsModuleName = false
                if tokenKind == .identifier, let tokenText = contents(for: token), tokenText == Keywords.RESULT {
                    return []
                }
            } else if tokenKind == .typeidentifier, let tokenText = contents(for: token), tokenText == Keywords.RESULT {
                resultTypeOffsets.append(stringView.location(fromByteOffset: token.range.location))
            }
        }

        return resultTypeOffsets
    }
}
