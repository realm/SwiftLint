import SwiftSyntax

struct UnavailableConditionRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "unavailable_condition",
        name: "Unavailable Condition",
        description: "Use #unavailable/#available instead of #available/#unavailable with an empty body.",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotSix,
        nonTriggeringExamples: [
            Example("""
            if #unavailable(iOS 13) {
              loadMainWindow()
            }
            """),
            Example("""
            if #available(iOS 9.0, *) {
              doSomething()
            } else {
              legacyDoSomething()
            }
            """),
            Example("""
            if #available(macOS 11.0, *) {
               // Do nothing
            } else if #available(macOS 10.15, *) {
               print("do some stuff")
            }
            """),
            Example("""
            if #available(macOS 11.0, *) {
               // Do nothing
            } else if i > 7 {
               print("do some stuff")
            } else if i < 2, #available(macOS 11.0, *) {
              print("something else")
            }
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("""
            if ↓#available(iOS 14.0) {

            } else {
              oldIos13TrackingLogic(isEnabled: ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
            }
            """),
            Example("""
            if ↓#available(iOS 14.0) {
              // we don't need to do anything here
            } else {
              oldIos13TrackingLogic(isEnabled: ASIdentifierManager.shared().isAdvertisingTrackingEnabled)
            }
            """),
            Example("""
            if ↓#available(iOS 13, *) {} else {
              loadMainWindow()
            }
            """),
            Example("""
            if ↓#unavailable(iOS 13) {
              // Do nothing
            } else if i < 2 {
              loadMainWindow()
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        UnavailableConditionRuleVisitor(viewMode: .sourceAccurate)
    }
}

private final class UnavailableConditionRuleVisitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: IfStmtSyntax) {
        guard node.body.statements.withoutTrivia().isEmpty else {
            return
        }

        guard let condition = node.conditions.onlyElement,
              let availability = asAvailabilityCondition(condition.condition) else {
            return
        }

        if otherAvailabilityCheckInvolved(ifStmt: node) {
            // If there are other conditional branches with availability checks it might not be possible
            // to just invert the first one.
            return
        }

        violations.append(
            ReasonedRuleViolation(
                position: availability.positionAfterSkippingLeadingTrivia,
                reason: reason(for: availability)
            )
        )
    }

    private func asAvailabilityCondition(_ condition: ConditionElementSyntax.Condition) -> SyntaxProtocol? {
        condition.as(AvailabilityConditionSyntax.self) ??
            condition.as(UnavailabilityConditionSyntax.self)
    }

    private func otherAvailabilityCheckInvolved(ifStmt: IfStmtSyntax) -> Bool {
        if let elseBody = ifStmt.elseBody, let nestedIfStatement = elseBody.as(IfStmtSyntax.self) {
            if nestedIfStatement.conditions.map(\.condition).compactMap(asAvailabilityCondition).isNotEmpty {
                return true
            }
            return otherAvailabilityCheckInvolved(ifStmt: nestedIfStatement)
        }
        return false
    }

    private func reason(for check: SyntaxProtocol) -> String {
        switch check {
        case is AvailabilityConditionSyntax:
            return "Use #unavailable instead of #available with an empty body."
        case is UnavailabilityConditionSyntax:
            return "Use #available instead of #unavailable with an empty body."
        default:
            queuedFatalError("Unknown availability check type.")
        }
    }
}
