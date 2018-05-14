import Foundation
import SourceKittenFramework

public struct NoFallthroughOnlyRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_fallthrough_only",
        name: "No Fallthrough Only",
        description: "Fallthroughs can only be used if the `case` contains at least one other statement.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            switch myvar {
            case 1:
                var a = 1
                fallthrough
            case 2:
                var a = 2
            }
            """,
            """
            switch myvar {
            case "a":
                var one = 1
                var two = 2
                fallthrough
            case "b": /* comment */
                var three = 3
            }
            """,
            """
            switch myvar {
            case 1:
               let one = 1
            case 2:
               // comment
               var two = 2
            }
            """
        ],
        triggeringExamples: [
            """
            switch myvar {
            case 1:
                ↓fallthrough
            case 2:
                var a = 1
            }
            """,
            """
            switch myvar {
            case 1:
                var a = 2
            case 2:
                ↓fallthrough
            case 3:
                var a = 3
            }
            """,
            """
            switch myvar {
            case 1: // comment
                ↓fallthrough
            }
            """,
            """
            switch myvar {
            case 1: /* multi
                line
                comment */
                ↓fallthrough
            case 2:
                var a = 2
            }
            """
        ]
    )

    public func validate(file: File,
                         kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard kind == .case,
            let length = dictionary.length,
            let offset = dictionary.offset,
            case let nsstring = file.contents.bridge(),
            let range = nsstring.byteRangeToNSRange(start: offset, length: length),
            let colonLocation = file.match(pattern: ":", range: range).first?.0.location
        else {
            return []
        }

        let caseBodyRange = NSRange(location: colonLocation,
                                    length: range.length + range.location - colonLocation)
        let nonCommentCaseBody = file.match(pattern: "\\w+", range: caseBodyRange).filter { _, syntaxKinds in
            return !Set(syntaxKinds).subtracting(SyntaxKind.commentKinds).isEmpty
        }

        guard nonCommentCaseBody.count == 1 else {
            return []
        }

        let nsRange = nonCommentCaseBody[0].0
        if nsstring.substring(with: nsRange) == "fallthrough" && nonCommentCaseBody[0].1 == [.keyword] {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, characterOffset: nsRange.location))]
        }

        return []
    }
}
