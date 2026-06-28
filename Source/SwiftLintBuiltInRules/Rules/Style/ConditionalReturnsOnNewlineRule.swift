import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ConditionalReturnsOnNewlineRule: Rule {
    var configuration = ConditionalReturnsOnNewlineConfiguration()

    static let description = RuleDescription(
        identifier: "conditional_returns_on_newline",
        name: "Conditional Returns on Newline",
        description: "Conditional statements should always return on the next line",
        kind: .style,
        nonTriggeringExamples: #examples([
            "guard true else {\n return true\n}",
            "guard true,\n let x = true else {\n return true\n}",
            "if true else {\n return true\n}",
            "if true,\n let x = true else {\n return true\n}",
            "if textField.returnKeyType == .Next {",
            "if true { // return }",
            """
            guard something
            else { return }
            """,
        ]),
        triggeringExamples: #examples([
            "↓guard true else { return }",
            "↓if true { return }",
            "↓if true { break } else { return }",
            "↓if true { break } else {       return }",
            "↓if true { return \"YES\" } else { return \"NO\" }",
            """
            ↓guard condition else { XCTFail(); return }
            """,
        ])
    )
}

private extension ConditionalReturnsOnNewlineRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IfExprSyntax) {
            if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.ifKeyword) {
                violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
                return
            }

            if let elseBody = node.elseBody?.as(CodeBlockSyntax.self), let elseKeyword = node.elseKeyword,
               isReturn(elseBody.statements.lastReturn, onTheSameLineAs: elseKeyword) {
                violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if configuration.ifOnly {
                return
            }

            if isReturn(node.body.statements.lastReturn, onTheSameLineAs: node.guardKeyword) {
                violations.append(node.guardKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func isReturn(_ returnStmt: ReturnStmtSyntax?, onTheSameLineAs token: TokenSyntax) -> Bool {
            guard let returnStmt else {
                return false
            }

            return locationConverter.location(for: returnStmt.returnKeyword.positionAfterSkippingLeadingTrivia).line ==
                locationConverter.location(for: token.positionAfterSkippingLeadingTrivia).line
        }
    }
}

private extension CodeBlockItemListSyntax {
    var lastReturn: ReturnStmtSyntax? {
        last?.item.as(ReturnStmtSyntax.self)
    }
}
