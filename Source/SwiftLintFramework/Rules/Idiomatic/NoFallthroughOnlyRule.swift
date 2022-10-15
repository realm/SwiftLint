import SwiftSyntax

public struct NoFallthroughOnlyRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_fallthrough_only",
        name: "No Fallthrough Only",
        description: "Fallthroughs can only be used if the `case` contains at least one other statement.",
        kind: .idiomatic,
        nonTriggeringExamples: NoFallthroughOnlyRuleExamples.nonTriggeringExamples,
        triggeringExamples: NoFallthroughOnlyRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NoFallthroughOnlyRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: SwitchCaseListSyntax) {
            let cases = node.compactMap { $0.as(SwitchCaseSyntax.self) }

            let localViolations = cases.enumerated()
                .compactMap { index, element -> AbsolutePosition? in
                    guard element.statements.count == 1,
                          let fallthroughStmt = element.statements.first?.item.as(FallthroughStmtSyntax.self) else {
                        return nil
                    }

                    if case let nextCaseIndex = cases.index(after: index),
                       nextCaseIndex < cases.endIndex,
                       case let nextCase = cases[nextCaseIndex],
                       nextCase.unknownAttr != nil {
                        return nil
                    }

                    return fallthroughStmt.positionAfterSkippingLeadingTrivia
                }

            violations.append(contentsOf: localViolations)
        }
    }
}
