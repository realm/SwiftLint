import SwiftSyntax

struct NoBlanketDisablesRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "no blanket disables",
        name: "No Blanket Disables",
        description: "swiftlint:disable commands should be re-enabled before the end of the file",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            // swiftlint:disable unused_import
            // swiftlint:enable unused_import
            """),
            Example("""
            // swiftlint:disable unused_import unused_declaration
            // swiftlint:enable unused_import
            // swiftlint:enable unused_declaration
            """),
            Example("// swiftlint:disable:this unused_import"),
            Example("// swiftlint:disable:next unused_import"),
            Example("// swiftlint:disable:previous unused_import")
        ],
        triggeringExamples: [
            Example("// swiftlint:disable unused_import"),
            Example("""
            // swiftlint:disable unused_import unused_declaration
            // swiftlint:enable unused_import
            """)
        ]
     )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        []
    }
}
