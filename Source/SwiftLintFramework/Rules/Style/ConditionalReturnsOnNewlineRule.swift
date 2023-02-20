import SwiftSyntax

struct ConditionalReturnsOnNewlineRule: ConfigurationProviderRule, OptInRule, SwiftSyntaxRule {
    var configuration = ConditionalReturnsOnNewlineConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "conditional_returns_on_newline",
        name: "Conditional Returns on Newline",
        description: "Conditional statements should always return on the next line",
        kind: .style,
        nonTriggeringExamples: [
            Example("guard true else {\n return true\n}"),
            Example("guard true,\n let x = true else {\n return true\n}"),
            Example("if true else {\n return true\n}"),
            Example("if true,\n let x = true else {\n return true\n}"),
            Example("if textField.returnKeyType == .Next {"),
            Example("if true { // return }"),
            Example("""
            guard something
            else { return }
            """)
        ],
        triggeringExamples: [
            Example("↓guard true else { return }"),
            Example("↓if true { return }"),
            Example("↓if true { break } else { return }"),
            Example("↓if true { break } else {       return }"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }"),
            Example("""
            ↓guard condition else { XCTFail(); return }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(
            ifOnly: configuration.ifOnly,
            locationConverter: file.locationConverter
        )
    }
}

private extension ConditionalReturnsOnNewlineRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let ifOnly: Bool
        private let locationConverter: SourceLocationConverter

        init(ifOnly: Bool, locationConverter: SourceLocationConverter) {
            self.ifOnly = ifOnly
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

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
            if ifOnly {
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
