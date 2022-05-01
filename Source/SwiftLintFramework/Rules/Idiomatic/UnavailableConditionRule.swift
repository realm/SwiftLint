import SourceKittenFramework
import SwiftSyntax

public struct UnavailableConditionRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unavailable_condition",
        name: "Unavailable Condition",
        description: "Use #unavailable instead of #available with an empty body.",
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
            """)
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
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let visitor = UnavailableConditionRuleVisitor()
        return visitor.walk(file: file) {
            $0.positions
        }.map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position.utf8Offset)))
        }
    }
}

private final class UnavailableConditionRuleVisitor: SyntaxVisitor {
    private(set) var positions: [AbsolutePosition] = []

    override func visitPost(_ node: IfStmtSyntax) {
        guard node.body.statements.withoutTrivia().isEmpty else {
            return
        }

        guard node.conditions.count == 1, let condition = node.conditions.first,
              let availability = condition.condition.as(AvailabilityConditionSyntax.self) else {
            return
        }

        positions.append(availability.positionAfterSkippingLeadingTrivia)
    }
}
