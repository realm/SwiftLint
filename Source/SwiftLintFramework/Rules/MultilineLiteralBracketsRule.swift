import Foundation
import SourceKittenFramework

public struct MultilineLiteralBracketsRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_literal_indentation",
        name: "Multiline Literal Brackets",
        description: "Multiline literals should have their surrounding brackets in a new line.",
        kind: .style,
        nonTriggeringExamples: [
            """
            let trio = ["harry", "ronald", "hermione"]
            let houseCup = ["gryffinder": 460, "hufflepuff": 370, "ravenclaw": 410, "slytherin": 450]
            """,
            """
            let trio = [
                "harry",
                "ronald",
                "hermione"
            ]
            let houseCup = [
                "gryffinder": 460,
                "hufflepuff": 370,
                "ravenclaw": 410,
                "slytherin": 450
            ]
            """,
            """
            let trio = [
                "harry", "ronald", "hermione"
            ]
            let houseCup = [
                "gryffinder": 460, "hufflepuff": 370,
                "ravenclaw": 410, "slytherin": 450
            ]
            """
        ],
        triggeringExamples: [
            """
            let trio = [↓"harry",
                        "ronald",
                        "hermione"
            ]
            """,
            """
            let houseCup = [↓"gryffinder": 460, "hufflepuff": 370,
                            "ravenclaw": 410, "slytherin": 450
            ]
            """,
            """
            let trio = [
                "harry",
                "ronald",
                "hermione"↓]
            """,
            """
            let houseCup = [
                "gryffinder": 460, "hufflepuff": 370,
                "ravenclaw": 410, "slytherin": 450↓]
            """,
            """
            class Hogwarts {
                let houseCup = [
                    "gryffinder": 460, "hufflepuff": 370,
                    "ravenclaw": 410, "slytherin": 450↓]
            }
            """
        ]
    )

    public func validate(
        file: File,
        kind: SwiftExpressionKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> [StyleViolation] {
        var violations = [StyleViolation]()

        if kind == .array || kind == .dictionary {
            let body = file.contents.substring(from: dictionary.bodyOffset!, length: dictionary.bodyLength!)
            let isMultiline = body.contains("\n")

            if isMultiline {
                if !body.hasPrefix("\n") {
                    violations.append(StyleViolation(
                        ruleDescription: type(of: self).description,
                        severity: configuration.severity,
                        location: Location(file: file, byteOffset: dictionary.bodyOffset!)
                    ))
                }

                if !body.hasSuffix("\n") {
                    violations.append(StyleViolation(
                        ruleDescription: type(of: self).description,
                        severity: configuration.severity,
                        location: Location(file: file, byteOffset: dictionary.bodyOffset! + dictionary.bodyLength!)
                    ))
                }
            }
        }

        return violations
    }
}
