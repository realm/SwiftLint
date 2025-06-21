import SwiftSyntax

@SwiftSyntaxRule
struct FunctionBodyLengthRule: Rule {
    var configuration = SeverityLevelsConfiguration<Self>(warning: 50, error: 100)

    static let description = RuleDescription(
        identifier: "function_body_length",
        name: "Function Body Length",
        description: "Function bodies should not span too many lines",
        kind: .metrics
    )
}

private extension FunctionBodyLengthRule {
    final class Visitor: BodyLengthVisitor<FunctionBodyLengthRule> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            if let body = node.body {
                registerViolations(
                    leftBrace: body.leftBrace,
                    rightBrace: body.rightBrace,
                    violationNode: node.funcKeyword,
                    objectName: "Function"
                )
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if let body = node.body {
                registerViolations(
                    leftBrace: body.leftBrace,
                    rightBrace: body.rightBrace,
                    violationNode: node.initKeyword,
                    objectName: "Function"
                )
            }
        }
    }
}
