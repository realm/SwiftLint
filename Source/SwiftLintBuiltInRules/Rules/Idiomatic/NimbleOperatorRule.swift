import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct NimbleOperatorRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "nimble_operator",
        name: "Nimble Operator",
        description: "Prefer Nimble operator overloads over free matcher functions",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "expect(seagull.squawk) != \"Hi!\"",
            "expect(\"Hi!\") == \"Hi!\"",
            "expect(10) > 2",
            "expect(10) >= 10",
            "expect(10) < 11",
            "expect(10) <= 10",
            "expect(x) === x",
            "expect(10) == 10",
            "expect(success) == true",
            "expect(value) == nil",
            "expect(value) != nil",
            "expect(object.asyncFunction()).toEventually(equal(1))",
            "expect(actual).to(haveCount(expected))",
            """
            foo.method {
                expect(value).to(equal(expectedValue), description: "Failed")
                return Bar(value: ())
            }
            """,
        ]),
        triggeringExamples: #examples([
            "↓expect(seagull.squawk).toNot(equal(\"Hi\"))",
            "↓expect(12).toNot(equal(10))",
            "↓expect(10).to(equal(10))",
            "↓expect(10, line: 1).to(equal(10))",
            "↓expect(10).to(beGreaterThan(8))",
            "↓expect(10).to(beGreaterThanOrEqualTo(10))",
            "↓expect(10).to(beLessThan(11))",
            "↓expect(10).to(beLessThanOrEqualTo(10))",
            "↓expect(x).to(beIdenticalTo(x))",
            "↓expect(success).to(beTrue())",
            "↓expect(success).to(beFalse())",
            "↓expect(value).to(beNil())",
            "↓expect(value).toNot(beNil())",
            "expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))",
        ]),
        corrections: #corrections([
            "↓expect(seagull.squawk).toNot(equal(\"Hi\"))": "expect(seagull.squawk) != \"Hi\"",
            "↓expect(\"Hi!\").to(equal(\"Hi!\"))": "expect(\"Hi!\") == \"Hi!\"",
            "↓expect(12).toNot(equal(10))": "expect(12) != 10",
            "↓expect(value1).to(equal(value2))": "expect(value1) == value2",
            "↓expect(   value1  ).to(equal(  value2.foo))": "expect(   value1  ) == value2.foo",
            "↓expect(value1).to(equal(10))": "expect(value1) == 10",
            "↓expect(10).to(beGreaterThan(8))": "expect(10) > 8",
            "↓expect(10).to(beGreaterThanOrEqualTo(10))": "expect(10) >= 10",
            "↓expect(10).to(beLessThan(11))": "expect(10) < 11",
            "↓expect(10).to(beLessThanOrEqualTo(10))": "expect(10) <= 10",
            "↓expect(x).to(beIdenticalTo(x))": "expect(x) === x",
            "↓expect(success).to(beTrue())": "expect(success) == true",
            "↓expect(success).to(beFalse())": "expect(success) == false",
            "↓expect(success).toNot(beFalse())": "expect(success) != false",
            "↓expect(success).toNot(beTrue())": "expect(success) != true",
            "↓expect(value).to(beNil())": "expect(value) == nil",
            "↓expect(value).toNot(beNil())": "expect(value) != nil",
            "expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))": "expect(10) > 2\n expect(10) > 2",
        ])
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
            numberOfCorrections += 1
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
