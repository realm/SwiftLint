import SwiftSyntax

@SwiftSyntaxRule
struct RedundantStringEnumValueRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_string_enum_value",
        name: "Redundant String Enum Value",
        description: "String enum values can be omitted when they are equal to the enumcase name",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            enum Numbers: String {
              case one
              case two
            }
            """),
            Example("""
            enum Numbers: Int {
              case one = 1
              case two = 2
            }
            """),
            Example("""
            enum Numbers: String {
              case one = "ONE"
              case two = "TWO"
            }
            """),
            Example("""
            enum Numbers: String {
              case one = "ONE"
              case two = "two"
            }
            """),
            Example("""
            enum Numbers: String {
              case one, two
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            enum Numbers: String {
              case one = ↓"one"
              case two = ↓"two"
            }
            """),
            Example("""
            enum Numbers: String {
              case one = ↓"one", two = ↓"two"
            }
            """),
            Example("""
            enum Numbers: String {
              case one, two = ↓"two"
            }
            """),
        ]
    )
}

private extension RedundantStringEnumValueRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: EnumDeclSyntax) {
            guard node.isStringEnum else {
                return
            }

            let enumsWithExplicitValues = node.memberBlock.members
                .flatMap { member -> EnumCaseElementListSyntax in
                    guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                        return EnumCaseElementListSyntax([])
                    }

                    return enumCaseDecl.elements
                }
                .filter { $0.rawValue != nil }

            let redundantMembersPositions = enumsWithExplicitValues
                .compactMap { element -> AbsolutePosition? in
                    guard let stringExpr = element.rawValue?.value.as(StringLiteralExprSyntax.self),
                          let segment = stringExpr.segments.onlyElement?.as(StringSegmentSyntax.self),
                          segment.content.text == element.name.text else {
                        return nil
                    }

                    return stringExpr.positionAfterSkippingLeadingTrivia
                }

            if redundantMembersPositions.count == enumsWithExplicitValues.count {
                violations.append(contentsOf: redundantMembersPositions)
            }
        }
    }
}

private extension EnumDeclSyntax {
    var isStringEnum: Bool {
        guard let inheritanceClause else {
            return false
        }

        return inheritanceClause.inheritedTypes.contains { elem in
            elem.type.as(IdentifierTypeSyntax.self)?.typeName == "String"
        }
    }
}
