import SwiftSyntax

struct EmptyXCTestMethodRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "empty_xctest_method",
        name: "Empty XCTest Method",
        description: "Empty XCTest method should be avoided.",
        kind: .lint,
        nonTriggeringExamples: EmptyXCTestMethodRuleExamples.nonTriggeringExamples,
        triggeringExamples: EmptyXCTestMethodRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        EmptyXCTestMethodRuleVisitor(viewMode: .sourceAccurate)
    }
}

private final class EmptyXCTestMethodRuleVisitor: ViolationsSyntaxVisitor {
    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        node.isXCTestCase ? .visitChildren : .skipChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if (node.modifiers.containsOverride || node.isTestMethod) && node.hasEmptyBody {
            violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension ClassDeclSyntax {
    var isXCTestCase: Bool {
        guard let inheritanceList = inheritanceClause?.inheritedTypeCollection else {
            return false
        }
        return inheritanceList.contains { type in
            type.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == "XCTestCase"
        }
    }
}

private extension FunctionDeclSyntax {
    var hasEmptyBody: Bool {
        if let body = body {
            return body.statements.isEmpty
        }
        return false
    }

    var isTestMethod: Bool {
        identifier.text.hasPrefix("test") && signature.input.parameterList.isEmpty
    }
}
