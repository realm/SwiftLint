import SwiftSyntax

struct ExplicitEnumRawValueRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "explicit_enum_raw_value",
        name: "Explicit Enum Raw Value",
        description: "Enums should be explicitly assigned their raw values",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            enum Numbers {
              case int(Int)
              case short(Int16)
            }
            """),
            Example("""
            enum Numbers: Int {
              case one = 1
              case two = 2
            }
            """),
            Example("""
            enum Numbers: Double {
              case one = 1.1
              case two = 2.2
            }
            """),
            Example("""
            enum Numbers: String {
              case one = "one"
              case two = "two"
            }
            """),
            Example("""
            protocol Algebra {}
            enum Numbers: Algebra {
              case one
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum Numbers: Int {
              case one = 10, ↓two, three = 30
            }
            """),
            Example("""
            enum Numbers: NSInteger {
              case ↓one
            }
            """),
            Example("""
            enum Numbers: String {
              case ↓one
              case ↓two
            }
            """),
            Example("""
            enum Numbers: String {
               case ↓one, two = "two"
            }
            """),
            Example("""
            enum Numbers: Decimal {
              case ↓one, ↓two
            }
            """),
            Example("""
            enum Outer {
                enum Numbers: Decimal {
                  case ↓one, ↓two
                }
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ExplicitEnumRawValueRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            if node.rawValue == nil, node.enclosingEnum()?.supportsRawValues == true {
                violations.append(node.identifier.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension SyntaxProtocol {
    func enclosingEnum() -> EnumDeclSyntax? {
        if let node = self.as(EnumDeclSyntax.self) {
            return node
        }

        return parent?.enclosingEnum()
    }
}
