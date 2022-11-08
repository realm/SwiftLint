import SwiftSyntax

struct ClassDelegateProtocolRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "class_delegate_protocol",
        name: "Class Delegate Protocol",
        description: "Delegate protocols should be class-only so they can be weakly referenced.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("protocol FooDelegate: class {}\n"),
            Example("protocol FooDelegate: class, BarDelegate {}\n"),
            Example("protocol Foo {}\n"),
            Example("class FooDelegate {}\n"),
            Example("@objc protocol FooDelegate {}\n"),
            Example("@objc(MyFooDelegate)\n protocol FooDelegate {}\n"),
            Example("protocol FooDelegate: BarDelegate {}\n"),
            Example("protocol FooDelegate: AnyObject {}\n"),
            Example("protocol FooDelegate: NSObjectProtocol {}\n"),
            Example("protocol FooDelegate where Self: BarDelegate {}\n"),
            Example("protocol FooDelegate where Self: AnyObject {}\n"),
            Example("protocol FooDelegate where Self: NSObjectProtocol {}\n")
        ],
        triggeringExamples: [
            Example("↓protocol FooDelegate {}\n"),
            Example("↓protocol FooDelegate: Bar {}\n"),
            Example("↓protocol FooDelegate where Self: StringProtocol {}\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ClassDelegateProtocolRule {
    private final class Visitor: ViolationsSyntaxVisitor {
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
        attributes?.contains { $0.as(AttributeSyntax.self)?.attributeName.text == "objc" } == true
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
