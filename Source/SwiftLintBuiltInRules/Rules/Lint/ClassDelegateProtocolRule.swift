import SwiftSyntax

struct ClassDelegateProtocolRule: SwiftSyntaxRule, ConfigurationProviderRule {
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
            Example("protocol FooDelegate where Self: NSObjectProtocol {}")
        ],
        triggeringExamples: [
            Example("↓protocol FooDelegate {}"),
            Example("↓protocol FooDelegate: Bar {}"),
            Example("↓protocol FooDelegate where Self: StringProtocol {}")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ClassDelegateProtocolRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            .allExcept(ProtocolDeclSyntax.self)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if node.identifier.text.hasSuffix("Delegate") &&
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
        inheritanceClause?.inheritedTypeCollection.contains { $0.typeName.is(ClassRestrictionTypeSyntax.self) } == true
    }

    func inheritsFromObjectOrDelegate() -> Bool {
        if inheritanceClause?.inheritedTypeCollection.contains(where: { $0.typeName.isObjectOrDelegate() }) == true {
            return true
        }

        guard let requirementList = genericWhereClause?.requirementList else {
            return false
        }

        return requirementList.contains { requirement in
            guard let conformanceRequirement = requirement.body.as(ConformanceRequirementSyntax.self),
                  let simpleLeftType = conformanceRequirement.leftTypeIdentifier.as(SimpleTypeIdentifierSyntax.self),
                  simpleLeftType.typeName == "Self"
            else {
                return false
            }

            return conformanceRequirement.rightTypeIdentifier.isObjectOrDelegate()
        }
    }
}

private extension TypeSyntax {
    func isObjectOrDelegate() -> Bool {
        guard let typeName = self.as(SimpleTypeIdentifierSyntax.self)?.typeName else {
            return false
        }

        return typeName == "AnyObject" || typeName == "NSObjectProtocol" || typeName.hasSuffix("Delegate")
    }
}
