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

private class EmptyXCTestMethodRuleVisitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let inheritanceList = node.inheritanceClause?.inheritedTypeCollection else {
            return .skipChildren
        }
        let isTestClass = inheritanceList
            .map(\.typeName)
            .compactMap { $0.as(SimpleTypeIdentifierSyntax.self) }
            .map(\.name)
            .map(\.text)
            .contains("XCTestCase")
        return isTestClass ? .visitChildren : .skipChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if node.isOverride, node.hasEmptyBody {
            violationPositions.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        } else if node.isTestMethod, node.hasEmptyBody {
            violationPositions.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionDeclSyntax {
    var isOverride: Bool {
        if let modifiers = modifiers {
            return modifiers.map(\.name).map(\.text).contains("override")
        }
        return false
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
