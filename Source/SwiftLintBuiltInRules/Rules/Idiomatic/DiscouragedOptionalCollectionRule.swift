import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct DiscouragedOptionalCollectionRule: Rule {
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
            if node.wrappedType.isCollectionType {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension SyntaxProtocol {
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
