import SwiftSyntax

public struct RedundantStringEnumValueRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_string_enum_value",
        name: "Redundant String Enum Value",
        description: "String enum values can be omitted when they are equal to the enumcase name.",
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
            """)
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
            """)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension RedundantStringEnumValueRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: EnumDeclSyntax) {
            guard node.isStringEnum else {
                return
            }

            let enumsWithExplicitValues = node.members.members
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
                          stringExpr.segments.count == 1,
                          let segment = stringExpr.segments.first?.as(StringSegmentSyntax.self),
                          segment.content.text == element.identifier.text else {
                        return nil
                    }

                    return stringExpr.positionAfterSkippingLeadingTrivia
                }

            if redundantMembersPositions.count == enumsWithExplicitValues.count {
                violationPositions.append(contentsOf: redundantMembersPositions)
            }
        }
    }
}

private extension EnumDeclSyntax {
    var isStringEnum: Bool {
        guard let inheritanceClause = inheritanceClause else {
            return false
        }

        return inheritanceClause.inheritedTypeCollection.contains { elem in
            elem.typeName.as(SimpleTypeIdentifierSyntax.self)?.typeName == "String"
        }
    }
}
