import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ExplicitEnumRawValueRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "explicit_enum_raw_value",
        name: "Explicit Enum Raw Value",
        description: "Enums should be explicitly assigned their raw values",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            """
            enum Numbers {
              case int(Int)
              case short(Int16)
            }
            """,
            """
            enum Numbers: Int {
              case one = 1
              case two = 2
            }
            """,
            """
            enum Numbers: Double {
              case one = 1.1
              case two = 2.2
            }
            """,
            """
            enum Numbers: String {
              case one = "one"
              case two = "two"
            }
            """,
            """
            protocol Algebra {}
            enum Numbers: Algebra {
              case one
            }
            """,
        ]),
        triggeringExamples: #examples([
            """
            enum Numbers: Int {
              case one = 10, ↓two, three = 30
            }
            """,
            """
            enum Numbers: NSInteger {
              case ↓one
            }
            """,
            """
            enum Numbers: String {
              case ↓one
              case ↓two
            }
            """,
            """
            enum Numbers: String {
               case ↓one, two = "two"
            }
            """,
            """
            enum Numbers: Decimal {
              case ↓one, ↓two
            }
            """,
            """
            enum Outer {
                enum Numbers: Decimal {
                  case ↓one, ↓two
                }
            }
            """,
        ])
    )
}

private extension ExplicitEnumRawValueRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            if node.rawValue == nil, node.enclosingEnum()?.supportsRawValues == true {
                violations.append(node.name.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension SyntaxProtocol {
    func enclosingEnum() -> EnumDeclSyntax? {
        if let node = `as`(EnumDeclSyntax.self) {
            return node
        }

        return parent?.enclosingEnum()
    }
}
