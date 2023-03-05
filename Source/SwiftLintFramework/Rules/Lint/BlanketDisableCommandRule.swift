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
            Example("// swiftlint:disable ↓unused_import"),
            Example("""
            // swiftlint:disable unused_import ↓unused_declaration
            // swiftlint:enable unused_import
            """),
            Example("""
            // swiftlint:disable unused_import
            // swiftlint:disable ↓unused_import
            // swiftlint:enable unused_import
            """),
            Example("""
            // swiftlint:enable ↓unused_import
            """)
        ].skipWrappingInCommentTests().skipDisableCommandTests()
     )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        var violations: [StyleViolation] = []
        var ruleIdentifierToCommandMap: [RuleIdentifier: Command] = [:]
        var disabledRuleIdentifiers: Set<RuleIdentifier> = []

        for command in file.commands {
            if command.action == .disable {
                violations += validateAlreadyDisabledRules(
                    for: command,
                    in: file,
                    disabledRuleIdentifiers: disabledRuleIdentifiers
                )
            }

            if command.action == .enable {
                violations += validateAlreadyEnabledRules(
                    for: command,
                    in: file,
                    disabledRuleIdentifiers: disabledRuleIdentifiers
                )
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

        violations += validateBlanketDisables(
            in: file,
            disabledRuleIdentifiers: disabledRuleIdentifiers,
            ruleIdentifierToCommandMap: ruleIdentifierToCommandMap
        )
        violations += validateAlwaysBlanketDisable(file: file)

        return violations
    }

    private func violation(
        for command: Command,
        ruleIdentifier: RuleIdentifier,
        in file: SwiftLintFile,
        reason: String
    ) -> StyleViolation {
        violation(for: command, ruleIdentifier: ruleIdentifier.stringRepresentation, in: file, reason: reason)
    }

    private func violation(
        for command: Command,
        ruleIdentifier: String,
        in file: SwiftLintFile,
        reason: String
    ) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: command.location(of: ruleIdentifier, in: file),
            reason: reason
        )
    }

    private func validateAlreadyDisabledRules(
        for command: Command,
        in file: SwiftLintFile,
        disabledRuleIdentifiers: Set<RuleIdentifier>
    ) -> [StyleViolation] {
        let alreadyDisabledRuleIdentifiers = command.ruleIdentifiers.intersection(disabledRuleIdentifiers)
        return alreadyDisabledRuleIdentifiers.map {
            let reason = "The disabled '\($0.stringRepresentation)' rule was already disabled"
            return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
        }
    }

    private func validateAlreadyEnabledRules(
        for command: Command,
        in file: SwiftLintFile,
        disabledRuleIdentifiers: Set<RuleIdentifier>
    ) -> [StyleViolation] {
        let notDisabledRuleIdentifiers = command.ruleIdentifiers.subtracting(disabledRuleIdentifiers)
        return notDisabledRuleIdentifiers.map {
            let reason = "The enabled '\($0.stringRepresentation)' rule was not disabled"
            return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
        }
    }

    private func validateBlanketDisables(
        in file: SwiftLintFile,
        disabledRuleIdentifiers: Set<RuleIdentifier>,
        ruleIdentifierToCommandMap: [RuleIdentifier: Command]
    ) -> [StyleViolation] {
        let allowedRuleIdentifiers = configuration.allowedRuleIdentifiers.union(
            configuration.alwaysBlanketDisableRuleIdentifiers
        )
        return disabledRuleIdentifiers.compactMap { disabledRuleIdentifier in
            if allowedRuleIdentifiers.contains(disabledRuleIdentifier.stringRepresentation) {
                return nil
            }

            if let command = ruleIdentifierToCommandMap[disabledRuleIdentifier] {
                let reason = "The disabled '\(disabledRuleIdentifier.stringRepresentation)' rule " +
                             "should be re-enabled before the end of the file"
                return violation(for: command, ruleIdentifier: disabledRuleIdentifier, in: file, reason: reason)
            }
            return nil
        }
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
                    return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
                })
            } else if command.modifier != nil {
                violations.append(contentsOf: intersection.map {
                    let reason = "The '\($0)' rule applies to the whole file and thus cannot be disabled locally " +
                                 "with 'previous', 'this' or 'next'"
                    return violation(for: command, ruleIdentifier: $0, in: file, reason: reason)
                })
            }
        }

        return violations
    }
}

private extension Command {
    func location(of ruleIdentifier: String, in file: SwiftLintFile) -> Location {
        var location = character
        if line > 0, line <= file.lines.count {
            let line = file.lines[line - 1].content
            if let ruleIdentifierIndex = line.range(of: ruleIdentifier)?.lowerBound {
                location = line.distance(from: line.startIndex, to: ruleIdentifierIndex) + 1
            }
        }
        return Location(file: file.file.path, line: line, character: location)
    }
}
