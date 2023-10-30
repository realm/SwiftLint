import SwiftSyntax

@SwiftSyntaxRule
struct DiscouragedOptionalCollectionRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "discouraged_optional_collection",
        name: "Discouraged Optional Collection",
        description: "Prefer empty collection over optional collection",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalCollectionExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalCollectionExamples.triggeringExamples
    )
}

private extension DiscouragedOptionalCollectionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: OptionalTypeSyntax) {
            guard node.wrappedType.isCollectionType else {
                return
            }

            if let variableDeclParent = node.nearestParent(ofType: VariableDeclSyntax.self) {
                violations.append(variableDeclParent.bindingSpecifier.positionAfterSkippingLeadingTrivia)
            } else if let functionParameterParent = node.nearestParent(ofType: FunctionParameterSyntax.self) {
                violations.append(functionParameterParent.firstName.positionAfterSkippingLeadingTrivia)
            } else if let functionDeclParent = node.nearestParent(ofType: FunctionDeclSyntax.self) {
                violations.append(functionDeclParent.name.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension SyntaxProtocol {
    func nearestParent<T: SyntaxProtocol>(ofType type: T.Type) -> T? {
        parent.flatMap { $0.as(type) ?? $0.nearestParent(ofType: type) }
    }

    var isCollectionType: Bool {
        self.is(ArrayTypeSyntax.self) ||
            self.is(DictionaryTypeSyntax.self) ||
            self.as(IdentifierTypeSyntax.self)?.isCollectionType == true
    }
}

private extension IdentifierTypeSyntax {
    var isCollectionType: Bool {
        ["Array", "Dictionary", "Set"].contains(name.text)
    }
}
