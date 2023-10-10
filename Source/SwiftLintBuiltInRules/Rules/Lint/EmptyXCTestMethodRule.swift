import SwiftSyntax

struct EmptyXCTestMethodRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = EmptyXCTestMethodConfiguration()

    static let description = RuleDescription(
        identifier: "empty_xctest_method",
        name: "Empty XCTest Method",
        description: "Empty XCTest method should be avoided",
        kind: .lint,
        nonTriggeringExamples: EmptyXCTestMethodRuleExamples.nonTriggeringExamples,
        triggeringExamples: EmptyXCTestMethodRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(testParentClasses: configuration.testParentClasses)
    }
}

extension EmptyXCTestMethodRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }
        private let testParentClasses: Set<String>

        init(testParentClasses: Set<String>) {
            self.testParentClasses = testParentClasses
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isXCTestCase(testParentClasses) ? .visitChildren : .skipChildren
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
