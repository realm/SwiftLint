import SwiftSyntax

@SwiftSyntaxRule
struct DuplicateEnumCasesRule: Rule {
    var configuration = SeverityConfiguration<Self>(.error)

    static let description = RuleDescription(
        identifier: "duplicate_enum_cases",
        name: "Duplicate Enum Cases",
        description: "Enum shouldn't contain multiple cases with the same name",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            enum PictureImport {
                case addImage(image: UIImage)
                case addData(data: Data)
            }
            """),
            Example("""
            enum A {
                case add(image: UIImage)
            }
            enum B {
                case add(image: UIImage)
            }
            """),
            Example("""
            enum Tag: String {
            #if CONFIG_A
                case value = "CONFIG_A"
            #elseif CONFIG_B
                case value = "CONFIG_B"
            #else
                case value = "CONFIG_DEFAULT"
            #endif
            }
            """),
            Example("""
            enum Target {
            #if os(iOS)
              case file
            #else
              case file(URL)
            #endif
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            enum PictureImport {
                case ↓add(image: UIImage)
                case addURL(url: URL)
                case ↓add(data: Data)
            }
            """),
        ]
    )
}

private extension DuplicateEnumCasesRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: EnumDeclSyntax) {
            let enumElements = node.memberBlock.members
                .flatMap { member -> EnumCaseElementListSyntax in
                    guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                        return EnumCaseElementListSyntax([])
                    }

                    return enumCaseDecl.elements
                }

            let elementsByName = enumElements.reduce(into: [String: [AbsolutePosition]]()) { elements, element in
                let name = String(element.name.text)
                elements[name, default: []].append(element.positionAfterSkippingLeadingTrivia)
            }

            let duplicatedElementPositions = elementsByName
                .filter { $0.value.count > 1 }
                .flatMap(\.value)

            violations.append(contentsOf: duplicatedElementPositions)
        }
    }
}
