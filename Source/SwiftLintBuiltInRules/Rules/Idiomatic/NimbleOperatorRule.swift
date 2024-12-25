import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct NimbleOperatorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "nimble_operator",
        name: "Nimble Operator",
        description: "Prefer Nimble operator overloads over free matcher functions",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("expect(seagull.squawk) != \"Hi!\""),
            Example("expect(\"Hi!\") == \"Hi!\""),
            Example("expect(10) > 2"),
            Example("expect(10) >= 10"),
            Example("expect(10) < 11"),
            Example("expect(10) <= 10"),
            Example("expect(x) === x"),
            Example("expect(10) == 10"),
            Example("expect(success) == true"),
            Example("expect(value) == nil"),
            Example("expect(value) != nil"),
            Example("expect(object.asyncFunction()).toEventually(equal(1))"),
            Example("expect(actual).to(haveCount(expected))"),
            Example("""
            foo.method {
                expect(value).to(equal(expectedValue), description: "Failed")
                return Bar(value: ())
            }
            """),
        ],
        triggeringExamples: [
            Example("↓expect(seagull.squawk).toNot(equal(\"Hi\"))"),
            Example("↓expect(12).toNot(equal(10))"),
            Example("↓expect(10).to(equal(10))"),
            Example("↓expect(10, line: 1).to(equal(10))"),
            Example("↓expect(10).to(beGreaterThan(8))"),
            Example("↓expect(10).to(beGreaterThanOrEqualTo(10))"),
            Example("↓expect(10).to(beLessThan(11))"),
            Example("↓expect(10).to(beLessThanOrEqualTo(10))"),
            Example("↓expect(x).to(beIdenticalTo(x))"),
            Example("↓expect(success).to(beTrue())"),
            Example("↓expect(success).to(beFalse())"),
            Example("↓expect(value).to(beNil())"),
            Example("↓expect(value).toNot(beNil())"),
            Example("expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))"),
        ],
        corrections: [
            Example("↓expect(seagull.squawk).toNot(equal(\"Hi\"))"): Example("expect(seagull.squawk) != \"Hi\""),
            Example("↓expect(\"Hi!\").to(equal(\"Hi!\"))"): Example("expect(\"Hi!\") == \"Hi!\""),
            Example("↓expect(12).toNot(equal(10))"): Example("expect(12) != 10"),
            Example("↓expect(value1).to(equal(value2))"): Example("expect(value1) == value2"),
            Example("↓expect(   value1  ).to(equal(  value2.foo))"): Example("expect(   value1  ) == value2.foo"),
            Example("↓expect(value1).to(equal(10))"): Example("expect(value1) == 10"),
            Example("↓expect(10).to(beGreaterThan(8))"): Example("expect(10) > 8"),
            Example("↓expect(10).to(beGreaterThanOrEqualTo(10))"): Example("expect(10) >= 10"),
            Example("↓expect(10).to(beLessThan(11))"): Example("expect(10) < 11"),
            Example("↓expect(10).to(beLessThanOrEqualTo(10))"): Example("expect(10) <= 10"),
            Example("↓expect(x).to(beIdenticalTo(x))"): Example("expect(x) === x"),
            Example("↓expect(success).to(beTrue())"): Example("expect(success) == true"),
            Example("↓expect(success).to(beFalse())"): Example("expect(success) == false"),
            Example("↓expect(success).toNot(beFalse())"): Example("expect(success) != false"),
            Example("↓expect(success).toNot(beTrue())"): Example("expect(success) != true"),
            Example("↓expect(value).to(beNil())"): Example("expect(value) == nil"),
            Example("↓expect(value).toNot(beNil())"): Example("expect(value) != nil"),
            Example("expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))"): Example("expect(10) > 2\n expect(10) > 2"),
        ]
    )
}

private extension NimbleOperatorRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard predicateDescription(for: node) != nil else {
                return
            }
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard let expectation = node.expectation(),
                  let predicate = predicatesMapping[expectation.operatorExpr.baseName.text],
                  let operatorExpr = expectation.operatorExpr(for: predicate),
                  let expectedValueExpr = expectation.expectedValueExpr(for: predicate) else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let elements = ExprListSyntax([
                expectation.baseExpr.with(\.trailingTrivia, .space),
                operatorExpr.with(\.trailingTrivia, .space),
                expectedValueExpr.with(\.trailingTrivia, node.trailingTrivia),
            ].map(ExprSyntax.init))
            return super.visit(SequenceExprSyntax(elements: elements))
        }
    }

    typealias MatcherFunction = String

    static let predicatesMapping: [MatcherFunction: PredicateDescription] = [
        "equal": (to: "==", toNot: "!=", .withArguments),
        "beIdenticalTo": (to: "===", toNot: "!==", .withArguments),
        "beGreaterThan": (to: ">", toNot: nil, .withArguments),
        "beGreaterThanOrEqualTo": (to: ">=", toNot: nil, .withArguments),
        "beLessThan": (to: "<", toNot: nil, .withArguments),
        "beLessThanOrEqualTo": (to: "<=", toNot: nil, .withArguments),
        "beTrue": (to: "==", toNot: "!=", .nullary(analogueValue: BooleanLiteralExprSyntax(booleanLiteral: true))),
        "beFalse": (to: "==", toNot: "!=", .nullary(analogueValue: BooleanLiteralExprSyntax(booleanLiteral: false))),
        "beNil": (to: "==", toNot: "!=", .nullary(analogueValue: NilLiteralExprSyntax(nilKeyword: .keyword(.nil)))),
    ]

    static func predicateDescription(for node: FunctionCallExprSyntax) -> PredicateDescription? {
        guard let expectation = node.expectation() else {
            return nil
        }
        return Self.predicatesMapping[expectation.operatorExpr.baseName.text]
    }
}

private extension FunctionCallExprSyntax {
    func expectation() -> Expectation? {
        guard trailingClosure == nil,
              arguments.count == 1,
              let memberExpr = calledExpression.as(MemberAccessExprSyntax.self),
              let kind = Expectation.Kind(rawValue: memberExpr.declName.baseName.text),
              let baseExpr = memberExpr.base?.as(FunctionCallExprSyntax.self),
              baseExpr.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "expect",
              let predicateExpr = arguments.first?.expression.as(FunctionCallExprSyntax.self),
              let operatorExpr = predicateExpr.calledExpression.as(DeclReferenceExprSyntax.self) else {
            return nil
        }

        let expected = predicateExpr.arguments.first?.expression
        return Expectation(kind: kind, baseExpr: baseExpr, operatorExpr: operatorExpr, expected: expected)
    }
}

private typealias PredicateDescription = (to: String, toNot: String?, arity: Arity)

private enum Arity {
    case nullary(analogueValue: any ExprSyntaxProtocol)
    case withArguments
}

private struct Expectation {
    let kind: Kind
    let baseExpr: FunctionCallExprSyntax
    let operatorExpr: DeclReferenceExprSyntax
    let expected: ExprSyntax?

    enum Kind {
        case positive
        case negative

        init?(rawValue: String) {
            switch rawValue {
            case "to":
                self = .positive
            case "toNot", "notTo":
                self = .negative
            default:
                return nil
            }
        }
    }

    func expectedValueExpr(for predicate: PredicateDescription) -> ExprSyntax? {
        switch predicate.arity {
        case .withArguments:
            expected
        case .nullary(let analogueValue):
            ExprSyntax(analogueValue)
        }
    }

    func operatorExpr(for predicate: PredicateDescription) -> BinaryOperatorExprSyntax? {
        let operatorStr =
            switch kind {
            case .negative:
                predicate.toNot
            case .positive:
                predicate.to
            }
        return operatorStr.map(BinaryOperatorExprSyntax.init)
    }
}
