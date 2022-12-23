import SwiftSyntax

struct NoFallthroughOnlyRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "no_fallthrough_only",
        name: "No Fallthrough only",
        description: "Fallthroughs can only be used if the `case` contains at least one other statement",
        kind: .idiomatic,
        nonTriggeringExamples: NoFallthroughOnlyRuleExamples.nonTriggeringExamples,
        triggeringExamples: NoFallthroughOnlyRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NoFallthroughOnlyRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: SwitchCaseListSyntax) {
            let cases = node.compactMap { $0.as(SwitchCaseSyntax.self) }

            let localViolations = cases.enumerated()
                .compactMap { index, element -> AbsolutePosition? in
                    if let fallthroughStmt = element.statements.onlyElement?.item.as(FallthroughStmtSyntax.self) {
                        if case let nextCaseIndex = cases.index(after: index),
                           nextCaseIndex < cases.endIndex,
                           case let nextCase = cases[nextCaseIndex],
                           nextCase.unknownAttr != nil {
                            return nil
                        }
                        return fallthroughStmt.positionAfterSkippingLeadingTrivia
                    }
                    return nil
                }

            violations.append(contentsOf: localViolations)
        }
    }
}
