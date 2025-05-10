import SwiftSyntax

@SwiftSyntaxRule
struct NSObjectPreferIsEqualRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "nsobject_prefer_isequal",
        name: "NSObject Prefer isEqual",
        description: "NSObject subclasses should implement isEqual instead of ==",
        kind: .lint,
        nonTriggeringExamples: NSObjectPreferIsEqualRuleExamples.nonTriggeringExamples,
        triggeringExamples: NSObjectPreferIsEqualRuleExamples.triggeringExamples
    )
}

private extension NSObjectPreferIsEqualRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.isSelfEqualFunction, node.isInObjcClass {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ClassDeclSyntax {
    var isObjC: Bool {
        if attributes.isObjc {
            return true
        }

        guard let inheritanceList = inheritanceClause?.inheritedTypes else {
            return false
        }
        return inheritanceList.contains { type in
            type.type.as(IdentifierTypeSyntax.self)?.name.text == "NSObject"
        }
    }
}

private extension FunctionDeclSyntax {
    var isSelfEqualFunction: Bool {
        guard
            modifiers.contains(keyword: .static),
            name.text == "==",
            returnsBool,
            case let parameterList = signature.parameterClause.parameters,
            parameterList.count == 2,
            let lhs = parameterList.first,
            let rhs = parameterList.last,
            lhs.firstName.text == "lhs",
            rhs.firstName.text == "rhs",
            lhs.type.trimmedDescription == rhs.type.trimmedDescription
        else {
            return false
        }

        return true
    }

    var returnsBool: Bool {
        signature.returnClause?.type.as(IdentifierTypeSyntax.self)?.name.text == "Bool"
    }
}

private extension SyntaxProtocol {
    var isInObjcClass: Bool {
        if let parentClass = parent?.as(ClassDeclSyntax.self) {
            return parentClass.isObjC
        }
        if parent?.as(DeclSyntax.self) != nil {
            return false
        }

        return parent?.isInObjcClass ?? false
    }
}

private extension AttributeListSyntax {
    var isObjc: Bool {
        contains(attributeNamed: "objc") || contains(attributeNamed: "objcMembers")
    }
}
