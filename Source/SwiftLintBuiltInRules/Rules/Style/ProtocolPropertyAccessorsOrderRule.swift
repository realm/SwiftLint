import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ProtocolPropertyAccessorsOrderRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "protocol_property_accessors_order",
        name: "Protocol Property Accessors Order",
        description: "When declaring properties in protocols, the order of accessors should be `get set`",
        kind: .style,
        // swiftlint:disable all
        nonTriggeringExamples: [
            #example {
                protocol Foo {
                    var bar: String { get set }
                }
            },
            #example {
                protocol Foo {
                    var bar: String { get }
                }
            },
            // Not valid Swift: a setter requires a getter. Kept as a string to cover the accessor count guard.
            """
            protocol Foo {
                var bar: String { set }
            }
            """.asExample(),
        ],
        triggeringExamples: [
            #example {
                protocol Foo {
                    var bar: String { /*>*/set get }
                }
            },
        ],
        corrections: [
            #example {
                protocol Foo {
                    var bar: String { /*>*/set get }
                }
            }: #example {
                protocol Foo {
                    var bar: String { get set }
                }
            },
        ]
        // swiftlint:enable all
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
            numberOfCorrections += 1
            let reversedAccessors = AccessorDeclListSyntax(Array(node.accessorsList.reversed()))
            return super.visit(node.with(\.accessors, .accessors(reversedAccessors)))
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
