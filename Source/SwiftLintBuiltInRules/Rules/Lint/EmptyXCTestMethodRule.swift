import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct EmptyXCTestMethodRule: Rule {
    var configuration = EmptyXCTestMethodConfiguration()

    static let description = RuleDescription(
        identifier: "empty_xctest_method",
        name: "Empty XCTest Method",
        description: "Empty XCTest method should be avoided",
        kind: .lint,
        nonTriggeringExamples: EmptyXCTestMethodRuleExamples.nonTriggeringExamples,
        triggeringExamples: EmptyXCTestMethodRuleExamples.triggeringExamples
    )
}

private extension EmptyXCTestMethodRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isXCTestCase(configuration.testParentClasses) ? .visitChildren : .skipChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if (node.modifiers.contains(keyword: .override) || node.isTestMethod) && node.hasEmptyBody {
                violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension FunctionDeclSyntax {
    var hasEmptyBody: Bool {
        if let body {
            return body.statements.isEmpty
        }
        return false
    }

    var isTestMethod: Bool {
        name.text.hasPrefix("test") && signature.parameterClause.parameters.isEmpty
    }
}
