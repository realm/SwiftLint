import SwiftSyntax

@SwiftSyntaxRule
struct ClassDelegateProtocolRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "class_delegate_protocol",
        name: "Class Delegate Protocol",
        description: "Delegate protocols should be class-only so they can be weakly referenced",
        kind: .lint,
        nonTriggeringExamples: [
            Example("protocol FooDelegate: class {}"),
            Example("protocol FooDelegate: class, BarDelegate {}"),
            Example("protocol Foo {}"),
            Example("class FooDelegate {}"),
            Example("@objc protocol FooDelegate {}"),
            Example("@objc(MyFooDelegate)\n protocol FooDelegate {}"),
            Example("protocol FooDelegate: BarDelegate {}"),
            Example("protocol FooDelegate: AnyObject {}"),
            Example("protocol FooDelegate: NSObjectProtocol {}"),
            Example("protocol FooDelegate where Self: BarDelegate {}"),
            Example("protocol FooDelegate where Self: AnyObject {}"),
            Example("protocol FooDelegate where Self: NSObjectProtocol {}"),
        ],
        triggeringExamples: [
            Example("↓protocol FooDelegate {}"),
            Example("↓protocol FooDelegate: Bar {}"),
            Example("↓protocol FooDelegate where Self: StringProtocol {}"),
        ]
    )
}

private extension ClassDelegateProtocolRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(ProtocolDeclSyntax.self)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if node.name.text.hasSuffix("Delegate") &&
                !node.hasObjCAttribute() &&
                !node.isClassRestricted() &&
                !node.inheritsFromObjectOrDelegate() {
                violations.append(node.protocolKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ProtocolDeclSyntax {
    func hasObjCAttribute() -> Bool {
        attributes.contains(attributeNamed: "objc")
    }

    func isClassRestricted() -> Bool {
        inheritanceClause?.inheritedTypes.contains { $0.type.is(ClassRestrictionTypeSyntax.self) } == true
    }

    func inheritsFromObjectOrDelegate() -> Bool {
        if inheritanceClause?.inheritedTypes.contains(where: { $0.type.isObjectOrDelegate() }) == true {
            return true
        }

        guard let requirementList = genericWhereClause?.requirements else {
            return false
        }

        return requirementList.contains { requirement in
            guard let conformanceRequirement = requirement.requirement.as(ConformanceRequirementSyntax.self),
                  let simpleLeftType = conformanceRequirement.leftType.as(IdentifierTypeSyntax.self),
                  simpleLeftType.typeName == "Self"
            else {
                return false
            }

            return conformanceRequirement.rightType.isObjectOrDelegate()
        }
    }
}

private extension TypeSyntax {
    func isObjectOrDelegate() -> Bool {
        guard let typeName = self.as(IdentifierTypeSyntax.self)?.typeName else {
            return false
        }

        return typeName == "AnyObject" || typeName == "NSObjectProtocol" || typeName.hasSuffix("Delegate")
    }
}
