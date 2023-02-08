import SwiftSyntax

struct NoBlanketDisablesRule: ConfigurationProviderRule {
    typealias ConfigurationType = NoBlanketDisablesConfiguration

    var configuration = NoBlanketDisablesConfiguration()

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
        ].skipWrappingInCommentTests()
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

        let allowedRuleIdentifiers = configuration.allowedRuleIdentifiers
        for disabledRuleIdentifier in disabledRuleIdentifiers {
            if allowedRuleIdentifiers.contains(disabledRuleIdentifier.stringRepresentation) {
                continue
            }

            if primaryRuleList.list[disabledRuleIdentifier.stringRepresentation] == nil {
                continue
            }

            if let command = ruleIdentifierToCommandMap[disabledRuleIdentifier] {
                let reason = "The disabled \(disabledRuleIdentifier.stringRepresentation) rule should be re-enabled before the end of the file"
                let violation = violation(forPath: file.file.path, line: command.line, character: command.character, reason: reason)
                violations.append(violation)
            }
        }

        violations.append(contentsOf: validateAlwaysBlanketDisable(file: file))

        return violations
    }

    private func violation(forPath path: String?, line: Int?, character: Int?, reason: String? = nil) -> StyleViolation {
        let location = Location(file: path, line: line, character: character)
        return StyleViolation(ruleDescription: Self.description, severity: configuration.severity, location: location, reason: reason)
    }

    private func validateAlwaysBlanketDisable(file: SwiftLintFile) -> [StyleViolation] {
        var violations: [StyleViolation] = []

        guard configuration.alwaysBlanketDisableRuleIdentifiers.isEmpty == false else {
            return []
        }

        for command in file.commands {
            let ruleIdentifiers: Set<String> = Set(command.ruleIdentifiers.map { $0.stringRepresentation })
            let intersection = ruleIdentifiers.intersection(configuration.alwaysBlanketDisableRuleIdentifiers)
            if intersection.isEmpty == false && (command.modifier != nil || command.action == .enable) {
                let reason = intersection.count == 1 ?
                "The \(intersection.first ?? "") rule should be disabled once for the entire file" :
                "The disabled rules should be disabled once for the entire file"
                let violation = violation(forPath: file.file.path, line: command.line, character: command.character, reason: reason)
                violations.append(violation)
            }
        }

        return violations
    }
}
