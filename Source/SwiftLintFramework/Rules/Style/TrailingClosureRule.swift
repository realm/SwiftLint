import Foundation
import SwiftSyntax

public struct TrailingClosureRule: OptInRule, SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = TrailingClosureConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_closure",
        name: "Trailing Closure",
        description: "Trailing closure syntax should be used whenever possible.",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo.map { $0 + 1 }\n"),
            Example("foo.bar()\n"),
            Example("foo.reduce(0) { $0 + 1 }\n"),
            Example("if let foo = bar.map({ $0 + 1 }) { }\n"),
            Example("foo.something(param1: { $0 }, param2: { $0 + 1 })\n"),
            Example("offsets.sorted { $0.offset < $1.offset }\n"),
            Example("foo.something({ return 1 }())"),
            Example("foo.something({ return $0 }(1))"),
            Example("foo.something(0, { return 1 }())")
        ],
        triggeringExamples: [
            Example("↓foo.map({ $0 + 1 })\n"),
            Example("↓foo.reduce(0, combine: { $0 + 1 })\n"),
            Example("↓offsets.sorted(by: { $0.offset < $1.offset })\n"),
            Example("↓foo.something(0, { $0 + 1 })\n")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        TrailingClosureRuleVisitor(onlySingleMutedParameter: configuration.onlySingleMutedParameter)
    }

    public func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation {
        StyleViolation(ruleDescription: Self.description,
                       severity: configuration.severityConfiguration.severity,
                       location: Location(file: file, position: position))
    }
}

private final class TrailingClosureRuleVisitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []
    private let onlySingleMutedParameter: Bool

    init(onlySingleMutedParameter: Bool) {
        self.onlySingleMutedParameter = onlySingleMutedParameter
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        guard node.trailingClosure == nil,
              node.leftParen != nil,
              node.argumentList.containsSingleClosureArgument,
              node.parent?.parent?.as(OptionalBindingConditionSyntax.self) == nil else {
            return
        }

        if onlySingleMutedParameter,
           (node.argumentList.count > 1 || node.argumentList.first?.label != nil) {
            return
        }

        violationPositions.append(node.positionAfterSkippingLeadingTrivia)
    }
}

private extension TupleExprElementListSyntax {
    var containsSingleClosureArgument: Bool {
        return filter { element in
            element.expression.is(ClosureExprSyntax.self)
        }.count == 1
    }
}
