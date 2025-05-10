import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct RawValueForCamelCasedCodableEnumRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "raw_value_for_camel_cased_codable_enum",
        name: "Raw Value for Camel Cased Codable Enum",
        description: "Camel cased cases of Codable String enums should have raw values",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            enum Numbers: Codable {
              case int(Int)
              case short(Int16)
            }
            """),
            Example("""
            enum Numbers: Int, Codable {
              case one = 1
              case two = 2
            }
            """),
            Example("""
            enum Numbers: Double, Codable {
              case one = 1.1
              case two = 2.2
            }
            """),
            Example("""
            enum Numbers: String, Codable {
              case one = "one"
              case two = "two"
            }
            """),
            Example("""
            enum Status: String, Codable {
                case OK, ACCEPTABLE
            }
            """),
            Example("""
            enum Status: String, Codable {
                case ok
                case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String {
                case ok
                case notAcceptable
                case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: Int, Codable {
                case ok
                case notAcceptable
                case maybeAcceptable = -1
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            enum Status: String, Codable {
                case ok
                case ↓notAcceptable
                case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String, Decodable {
               case ok
               case ↓notAcceptable
               case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String, Encodable {
               case ok
               case ↓notAcceptable
               case maybeAcceptable = "maybe_acceptable"
            }
            """),
            Example("""
            enum Status: String, Codable {
                case ok
                case ↓notAcceptable
                case maybeAcceptable = "maybe_acceptable"
            }
            """),
        ]
    )
}

private extension RawValueForCamelCasedCodableEnumRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private let codableTypes = Set(["Codable", "Decodable", "Encodable"])

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let inheritedTypes = node.inheritanceClause?.inheritedTypes.typeNames,
                  !inheritedTypes.isDisjoint(with: codableTypes),
                  inheritedTypes.contains("String") else {
                return .skipChildren
            }

            return .visitChildren
        }

        override func visitPost(_ node: EnumCaseElementSyntax) {
            guard node.rawValue == nil,
                  case let name = node.name.text,
                  !name.isUppercase(),
                  !name.isLowercase() else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension InheritedTypeListSyntax {
    var typeNames: Set<String> {
        Set(compactMap { $0.type.as(IdentifierTypeSyntax.self) }.map(\.name.text))
    }
}
