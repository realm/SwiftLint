import SwiftSyntax

public struct NSObjectPreferIsEqualRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nsobject_prefer_isequal",
        name: "NSObject Prefer isEqual",
        description: "NSObject subclasses should implement isEqual instead of ==.",
        kind: .lint,
        nonTriggeringExamples: NSObjectPreferIsEqualRuleExamples.nonTriggeringExamples,
        triggeringExamples: NSObjectPreferIsEqualRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NSObjectPreferIsEqualRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isObjC ? .visitChildren : .skipChildren
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
            if node.isSelfEqualFunction {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ClassDeclSyntax {
    var isObjC: Bool {
        if attributes?.isObjc == true {
            return true
        }

        guard let inheritanceList = inheritanceClause?.inheritedTypeCollection else {
            return false
        }
        return inheritanceList.contains { type in
            type.typeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == "NSObject"
        }
    }
}

private extension FunctionDeclSyntax {
    var isSelfEqualFunction: Bool {
        guard
            modifiers.isStatic,
            identifier.text == "==",
            returnsBool,
            case let parameterList = signature.input.parameterList,
            parameterList.count == 2,
            let lhs = parameterList.first,
            let rhs = parameterList.last,
            lhs.firstName?.text == "lhs",
            rhs.firstName?.text == "rhs",
            let lhsTypeDescription = lhs.type?.withoutTrivia().description,
            let rhsTypeDescription = rhs.type?.withoutTrivia().description,
            lhsTypeDescription == rhsTypeDescription
        else {
            return false
        }

        return true
    }

    var returnsBool: Bool {
        signature.output?.returnType.as(SimpleTypeIdentifierSyntax.self)?.name.text == "Bool"
    }
}

private extension ModifierListSyntax? {
    var isStatic: Bool {
        guard let modifiers = self else {
            return false
        }

        return modifiers.contains { $0.name.tokenKind == .staticKeyword }
    }
}

private extension AttributeListSyntax {
    var isObjc: Bool {
        contains { $0.as(AttributeSyntax.self)?.attributeName.text == "objc" }
    }
}
