import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ProtocolPropertyAccessorsOrderRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "protocol_property_accessors_order",
        name: "Protocol Property Accessors Order",
        description: "When declaring properties in protocols, the order of accessors should be `get set`",
        kind: .style,
        nonTriggeringExamples: [
            Example("protocol Foo {\n var bar: String { get set }\n }"),
            Example("protocol Foo {\n var bar: String { get }\n }"),
            Example("protocol Foo {\n var bar: String { set }\n }"),
        ],
        triggeringExamples: [
            Example("protocol Foo {\n var bar: String { ↓set get }\n }")
        ],
        corrections: [
            Example("protocol Foo {\n var bar: String { ↓set get }\n }"):
                Example("protocol Foo {\n var bar: String { get set }\n }"),
        ]
    )
}

private extension ProtocolPropertyAccessorsOrderRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(ProtocolDeclSyntax.self, VariableDeclSyntax.self)
        }

        override func visitPost(_ node: AccessorBlockSyntax) {
            guard node.hasViolation else {
                return
            }

            violations.append(node.accessors.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
            guard node.hasViolation else {
                return super.visit(node)
            }

            correctionPositions.append(node.accessors.positionAfterSkippingLeadingTrivia)

            let reversedAccessors = AccessorDeclListSyntax(Array(node.accessorsList.reversed()))
            return super.visit(
                node.with(\.accessors, .accessors(reversedAccessors))
            )
        }
    }
}

private extension AccessorBlockSyntax {
    var hasViolation: Bool {
        let accessorsList = accessorsList
        return accessorsList.count == 2
            && accessorsList.allSatisfy({ $0.body == nil })
            && accessorsList.first?.accessorSpecifier.tokenKind == .keyword(.set)
    }
}
