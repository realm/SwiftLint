import SwiftSyntax

struct BlanketDisableCommandRule: ConfigurationProviderRule {
    var configuration = BlanketDisableCommandConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "blanket_disable_command",
        name: "Blanket Disable Command",
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
            Example("// ↓swiftlint:disable unused_import"),
            Example("""
            // ↓swiftlint:disable unused_import unused_declaration
            // swiftlint:enable unused_import
            """),
            Example("""
            // swiftlint:disable unused_import
            // ↓swiftlint:disable unused_import
            // swiftlint:enable unused_import
            """),
            Example("""
            // ↓swiftlint:enable unused_import
            """)
        ].skipWrappingInCommentTests().skipDisableCommandTests()
     )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        var violations: [StyleViolation] = []
        var ruleIdentifierToCommandMap: [RuleIdentifier: Command] = [:]
        var disabledRuleIdentifiers: Set<RuleIdentifier> = []

        for command in file.commands {
            if command.action == .disable {
                let alreadyDisabledRuleIdentifiers = command.ruleIdentifiers.intersection(disabledRuleIdentifiers)
                violations.append(contentsOf: alreadyDisabledRuleIdentifiers.map {
                    let reason = "The disabled '\($0.stringRepresentation)' rule was already disabled"
                    return violation(forFile: file, command: command, reason: reason)
                })
            }

            if command.action == .enable {
                let notDisabledRuleIdentifiers = command.ruleIdentifiers.subtracting(disabledRuleIdentifiers)
                violations.append(contentsOf: notDisabledRuleIdentifiers.map {
                    let reason = "The enabled '\($0.stringRepresentation)' rule was not disabled"
                    return violation(forFile: file, command: command, reason: reason)
                })
            }

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

            if let command = ruleIdentifierToCommandMap[disabledRuleIdentifier] {
                let reason = "The disabled '\(disabledRuleIdentifier.stringRepresentation)' rule " +
                             "should be re-enabled before the end of the file"
                violations.append(violation(forFile: file, command: command, reason: reason))
            }
        }

        violations.append(contentsOf: validateAlwaysBlanketDisable(file: file))

        return violations
    }

    private func violation(forFile file: SwiftLintFile, command: Command, reason: String) -> StyleViolation {
        var character = command.character
        if command.line > 0, command.line <= file.lines.count {
            let line = file.lines[command.line - 1].content
            if let commandIndex = line.range(of: "swiftlint:")?.lowerBound {
                character = line.distance(from: line.startIndex, to: commandIndex) + 1
            }
        }

        return StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file.file.path, line: command.line, character: character),
            reason: reason
        )
    }

    private func validateAlwaysBlanketDisable(file: SwiftLintFile) -> [StyleViolation] {
        var violations: [StyleViolation] = []

        guard configuration.alwaysBlanketDisableRuleIdentifiers.isEmpty == false else {
            return []
        }

        for command in file.commands {
            let ruleIdentifiers: Set<String> = Set(command.ruleIdentifiers.map { $0.stringRepresentation })
            let intersection = ruleIdentifiers.intersection(configuration.alwaysBlanketDisableRuleIdentifiers)
            if command.action == .enable {
                violations.append(contentsOf: intersection.map {
                    let reason = "The '\($0)' rule applies to the whole file and thus doesn't need to be re-enabled"
                    return violation(forFile: file, command: command, reason: reason)
                })
            } else if command.modifier != nil {
                violations.append(contentsOf: intersection.map {
                    let reason = "The '\($0)' rule applies to the whole file and thus cannot be disabled locally " +
                                 "with 'previous', 'this' or 'next'"
                    return violation(forFile: file, command: command, reason: reason)
                })
            }
        }

        return violations
    }
}
