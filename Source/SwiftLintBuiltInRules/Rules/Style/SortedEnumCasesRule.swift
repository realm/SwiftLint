import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct SortedEnumCasesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "sorted_enum_cases",
        name: "Sorted Enum Cases",
        description: "Enum cases should be sorted",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            enum foo {
                case a
                case b
                case c
            }
            """),
            Example("""
            enum foo {
                case example
                case exBoyfriend
            }
            """),
            Example("""
            enum foo {
                case a
                case B
                case c
            }
            """),
            Example("""
            enum foo {
                case a, b, c
            }
            """),
            Example("""
            enum foo {
                case a
                case b, c
            }
            """),
            Example("""
            enum foo {
                case a(foo: Foo)
                case b(String), c
            }
            """),
            Example("""
            enum foo {
                case a
                case b, C, d
            }
            """),
            Example("""
            @frozen
            enum foo {
                case b
                case a
                case c, f, d
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            enum foo {
                ↓case b
                ↓case a
                case c
            }
            """),
            Example("""
            enum foo {
                ↓case B
                ↓case a
                case c
            }
            """),
            Example("""
            enum foo {
                case ↓b, ↓a, c
            }
            """),
            Example("""
            enum foo {
                case ↓B, ↓a, c
            }
            """),
            Example("""
            enum foo {
                ↓case b, c
                ↓case a
            }
            """),
            Example("""
            enum foo {
                case a
                case b, ↓d, ↓c
            }
            """),
            Example("""
            enum foo {
                case a(foo: Foo)
                case ↓c, ↓b(String)
            }
            """),
        ]
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
