import SourceKittenFramework
import SwiftSyntax

public struct UnavailableConditionRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let visitor = UnavailableConditionRuleVisitor()
        return visitor.walk(file: file, handler: \.availabilityChecks).map { check in
            StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: Location(
                    file: file,
                    byteOffset: ByteCount(check.positionAfterSkippingLeadingTrivia.utf8Offset)),
                reason: provideViolationReason(for: check)
            )
        }
    }

    private func provideViolationReason(for check: SyntaxProtocol) -> String {
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

private final class UnavailableConditionRuleVisitor: SyntaxVisitor {
    private(set) var availabilityChecks: [SyntaxProtocol] = []

    override func visitPost(_ node: IfStmtSyntax) {
        guard node.body.statements.withoutTrivia().isEmpty else {
            return
        }

        guard node.conditions.count == 1, let condition = node.conditions.first,
              let availability = asAvailabilityCondition(condition.condition) else {
            return
        }

        if otherAvailabilityCheckInvolved(ifStmt: node) {
            // If there are other conditional branches with availablilty checks it might not be possible
            // to just invert the first one.
            return
        }

        availabilityChecks.append(availability)
    }

    private func asAvailabilityCondition(_ condition: Syntax) -> SyntaxProtocol? {
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
}
