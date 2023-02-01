import Foundation
import SwiftSyntax

struct InvalidSwiftLintCommandRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "invalid_swiftlint_command",
        name: "Invalid SwiftLint Command",
        description: "swiftlint command does not have a valid action or modifier",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// swiftlint:disable unused_import"),
            Example("// swiftlint:enable unused_import"),
            Example("// swiftlint:disable:next unused_import"),
            Example("// swiftlint:disable:previous unused_import"),
            Example("// swiftlint:disable:this unused_import")
        ],
        triggeringExamples: [
            Example("// swiftlint:"),
            Example("// swiftlint: "),
            Example("// swiftlint::"),
            Example("// swiftlint:: "),
            Example("// swiftlint:disable"),
            Example("// swiftlint:dissable unused_import"),
            Example("// swiftlint:enaaaable unused_import"),
            Example("// swiftlint:disable:nxt unused_import"),
            Example("// swiftlint:enable:prevus unused_import"),
            Example("// swiftlint:enable:ths unused_import"),
            Example("// swiftlint:enable"),
            Example("// swiftlint:enable:"),
            Example("// swiftlint:enable: "),
            Example("// swiftlint:disable: unused_import")
        ].skipWrappingInCommentTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        file.invalidCommands.map {
            let location = Location(file: file.path, line: $0.line, character: $0.character)
            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: location
            )
        }
    }
}
