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
            """
        ]
    )

    public func validate(
        file: File,
        kind: SwiftExpressionKind,
        dictionary: [String: SourceKitRepresentable]
    ) -> [StyleViolation] {
        return [] // TODO: not yet implemented
    }
}
