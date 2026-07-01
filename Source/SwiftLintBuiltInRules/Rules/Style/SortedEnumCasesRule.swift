import Foundation
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct SortedEnumCasesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "sorted_enum_cases",
        name: "Sorted Enum Cases",
        description: "Enum cases should be sorted",
        kind: .style,
        nonTriggeringExamples: #examples([
            """
            enum foo {
                case a
                case b
                case c
            }
            """,
            """
            enum foo {
                case example
                case exBoyfriend
            }
            """,
            """
            enum foo {
                case a
                case B
                case c
            }
            """,
            """
            enum foo {
                case a, b, c
            }
            """,
            """
            enum foo {
                case a
                case b, c
            }
            """,
            """
            enum foo {
                case a(foo: Foo)
                case b(String), c
            }
            """,
            """
            enum foo {
                case a
                case b, C, d
            }
            """,
            """
            @frozen
            enum foo {
                case b
                case a
                case c, f, d
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            enum foo {
                ↓case b
                ↓case a
                case c
            }
            """,
            """
            enum foo {
                ↓case B
                ↓case a
                case c
            }
            """,
            """
            enum foo {
                case ↓b, ↓a, c
            }
            """,
            """
            enum foo {
                case ↓B, ↓a, c
            }
            """,
            """
            enum foo {
                ↓case b, c
                ↓case a
            }
            """,
            """
            enum foo {
                case a
                case b, ↓d, ↓c
            }
            """,
            """
            enum foo {
                case a(foo: Foo)
                case ↓c, ↓b(String)
            }
            """,
        ])
    )
}

private extension SortedEnumCasesRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(EnumDeclSyntax.self)
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            guard !node.attributes.contains(attributeNamed: "frozen") else {
                return .skipChildren
            }

            let cases = node.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            let sortedCases = cases
                .sorted(by: {
                    let lhs = $0.elements.first!.name.text
                    let rhs = $1.elements.first!.name.text
                    return lhs.caseInsensitiveCompare(rhs) == .orderedAscending
                })

            zip(sortedCases, cases).forEach { sortedCase, currentCase in
                if sortedCase.elements.first?.name.text != currentCase.elements.first?.name.text {
                    violations.append(currentCase.positionAfterSkippingLeadingTrivia)
                }
            }

            return .visitChildren
        }

        override func visitPost(_ node: EnumCaseDeclSyntax) {
            let sortedElements = node.elements.sorted(by: {
                $0.name.text.caseInsensitiveCompare($1.name.text) == .orderedAscending
            })

            zip(sortedElements, node.elements).forEach { sortedElement, currentElement in
                if sortedElement.name.text != currentElement.name.text {
                    violations.append(currentElement.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}
