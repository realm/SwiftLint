import SwiftSyntax

public struct EmptyXCTestMethodRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = EmptyXCTestMethodConfiguration()

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
        EmptyXCTestMethodRuleVisitor(testParentClasses: configuration.testParentClasses)
    }
    
    public func makeViolation(file: SwiftLintFile, position: AbsolutePosition) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, position: position)
        )
    }
}

private final class EmptyXCTestMethodRuleVisitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []
    private let testParentClasses: Set<String>

    init(testParentClasses: Set<String>) {
        self.testParentClasses = testParentClasses
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        isNodeATestCase(node) ? .visitChildren : .skipChildren
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
    
    private func isNodeATestCase(_ node: ClassDeclSyntax) -> Bool {
        testParentClasses.intersection(node.inheritedTypes).isNotEmpty
    }
}

private extension ClassDeclSyntax {
    var inheritedTypes: [String] {
        guard let inheritanceList = inheritanceClause?.inheritedTypeCollection else {
            return []
        }
        return inheritanceList.compactMap { $0.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text }
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
