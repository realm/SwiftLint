import SwiftSyntax

public struct EmptyXCTestMethodRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_xctest_method",
        name: "Empty XCTest Method",
        description: "Empty XCTest method should be avoided.",
        kind: .lint,
        nonTriggeringExamples: EmptyXCTestMethodRuleExamples.nonTriggeringExamples,
        triggeringExamples: EmptyXCTestMethodRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        EmptyXCTestMethodRuleVisitor()
    }
}

private final class EmptyXCTestMethodRuleVisitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        node.isXCTestCase ? .visitChildren : .skipChildren
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        .skipChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if (node.isOverride || node.isTestMethod) && node.hasEmptyBody {
            violationPositions.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
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
    var isOverride: Bool {
        modifiers?.contains { $0.name.text == "override" } ?? false
    }

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
