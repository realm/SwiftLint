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
            """
            @testable import Foo
            import Foundation
            import Result
            func foo() -> Result<String, Error> { }
            func foo(result: Result<String, Error>) ->  {
                let r: Result<String> = result
            }
            func Result() {
            }
            """
        ],
        triggeringExamples: [
            """
            @testable import Foo
            import Foundation
            func foo() -> ↓Result<String, Error> { }
            func foo(result: ↓Result<String, Error>) ->  {
                let r: ↓Result<String> = result
            }
            func Result() {
            }
            """
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.checkIfMissingImportResult().map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}

extension File {
    func checkIfMissingImportResult() -> [NSRange] {
        let kImport = "import"
        let kResult = "Result"

        let contentsNSString = contents.bridge()
        func getTextFrom(_ token: SyntaxToken) -> String? {
            return contentsNSString.substringWithByteRange(start: token.offset, length: token.length)
        }

        var nextTokenIsModuleName = false
        var resultTypeOffsets: [NSRange] = []
        let tokens = syntaxMap.tokens
        for token in tokens {
            guard let tokenKind = SyntaxKind(rawValue: token.type) else {
                continue
            }
            if tokenKind == .keyword, let tokenText = getTextFrom(token), tokenText == kImport {
                nextTokenIsModuleName = true
                continue
            }
            if nextTokenIsModuleName {
                nextTokenIsModuleName = false
                if tokenKind == .identifier, let tokenText = getTextFrom(token), tokenText == kResult {
                    return []
                }
            } else if tokenKind == .typeidentifier, let tokenText = getTextFrom(token), tokenText == kResult {
                if let range = contentsNSString.byteRangeToNSRange(start: token.offset, length: token.length) {
                    resultTypeOffsets.append(range)
                }
            }
        }

        return resultTypeOffsets
    }
}
