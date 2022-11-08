import SwiftSyntax

struct LargeTupleRule: SourceKitFreeRule, ConfigurationProviderRule {
    var configuration = SeverityLevelsConfiguration(warning: 2, error: 3)

    init() {}

    static let description = RuleDescription(
        identifier: "large_tuple",
        name: "Large Tuple",
        description: "Tuples shouldn't have too many members. Create a custom type instead.",
        kind: .metrics,
        nonTriggeringExamples: LargeTupleRuleExamples.nonTriggeringExamples,
        triggeringExamples: LargeTupleRuleExamples.triggeringExamples
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        LargeTupleRuleVisitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.violationPositions)
            .sorted(by: { $0.position < $1.position })
            .compactMap { position, size in
                for parameter in configuration.params where size > parameter.value {
                    let reason = "Tuples should have at most \(configuration.warning) members."
                    return StyleViolation(ruleDescription: Self.description,
                                          severity: parameter.severity,
                                          location: Location(file: file, position: position),
                                          reason: reason)
                }

                return nil
            }
    }
}

private final class LargeTupleRuleVisitor: SyntaxVisitor {
    private(set) var violationPositions: [(position: AbsolutePosition, memberCount: Int)] = []

    override func visitPost(_ node: TupleTypeSyntax) {
        violationPositions.append((node.positionAfterSkippingLeadingTrivia, node.elements.count))
    }
}
