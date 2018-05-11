import Foundation
import SourceKittenFramework

public struct NoFallthroughOnlyRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_fallthrough_only",
        name: "No Fallthrough Only",
        description: "Fallthroughs can only be used if the `case` contains at least one other statement.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            switch {
            case 1:
                var a = 1
                fallthrough
            case 2:
                var a = 2
            }
            """,
            """
            switch {
            case "a":
                var one = 1
                var two = 2
                fallthrough
            case "b": /* comment */
                var three = 3
            }
            """,
            """
            switch {
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
            switch {
            case 1:
                fallthrough
            case 2:
                var a = 1
            }
            """,
            """
            switch {
            case 1:
                var a = 2
            case 2:
                fallthrough
            case 3:
                var a = 3
            }
            """,
            """
            switch {
            case 1: // comment
                fallthrough
            }
            """,
            """
            switch {
            case 1: /* multi
                line
                comment */
                fallthrough
            case 2:
                var a = 2
            }
            """
        ]
    )

    public func validate(file: File,
                         kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard kind == StatementKind.case else {
            return []
        }

        guard
            let length = dictionary.length,
            let offset = dictionary.offset
        else {
            return []
        }

        let pattern = "case[^:]+:\\s*" + // match start of case
            "((//.*\\n)|" + // match double-slash comments, or
            "(/\\*(.|\\n)*\\*/))*" + // match block comments (zero or more consecutive comments)
            "\\s*fallthrough" // look for fallthrough immediately following case and consecutive comments
        let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length)

        return file.match(pattern: pattern, range: range).map { nsRange, _ in
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: nsRange.location))
        }
    }
}
