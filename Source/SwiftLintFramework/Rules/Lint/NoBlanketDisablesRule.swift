import SwiftSyntax

struct NoBlanketDisablesRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "no_blanket_disables",
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
        var violations: [StyleViolation] = []
        var ruleIdentifierToCommandMap: [RuleIdentifier: Command] = [:]
        var disabledRuleIdentifiers: Set<RuleIdentifier> = []
        for command in file.commands {
            if command.modifier != nil {
                continue
            }
            if command.action == .disable {
                disabledRuleIdentifiers.formUnion(command.ruleIdentifiers)
                command.ruleIdentifiers.forEach { ruleIdentifierToCommandMap[$0] = command }
            }
            if command.action == .enable {
                disabledRuleIdentifiers.subtract(command.ruleIdentifiers)
                command.ruleIdentifiers.forEach { ruleIdentifierToCommandMap.removeValue(forKey: $0) }
            }
        }

        for disabledRuleIdentifier in disabledRuleIdentifiers {
            if disabledRuleIdentifier == "file_length" ||
                disabledRuleIdentifier == "single_test_class" {
                continue
            }

            if let command = ruleIdentifierToCommandMap[disabledRuleIdentifier] {
                let location = Location(file: file.file.path, line: command.line, character: command.character)
                let violation = StyleViolation(ruleDescription: Self.description,
                                               severity: configuration.severity,
                                               location: location)
                violations.append(violation)
            }
        }

        return violations
    }
}
