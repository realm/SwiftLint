import SwiftSyntax

struct DuplicateEnumCasesRule: ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

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
            """)
        ],
        triggeringExamples: [
            Example("""
            enum PictureImport {
                case ↓add(image: UIImage)
                case addURL(url: URL)
                case ↓add(data: Data)
            }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DuplicateEnumCasesRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: EnumDeclSyntax) {
            let enumElements = node.members.members
                .flatMap { member -> EnumCaseElementListSyntax in
                    guard let enumCaseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                        return EnumCaseElementListSyntax([])
                    }

                    return enumCaseDecl.elements
                }

            let elementsByName = enumElements.reduce(into: [String: [AbsolutePosition]]()) { elements, element in
                let name = String(element.identifier.text)
                elements[name, default: []].append(element.positionAfterSkippingLeadingTrivia)
            }

            let duplicatedElementPositions = elementsByName
                .filter { $0.value.count > 1 }
                .flatMap { $0.value }

            violations.append(contentsOf: duplicatedElementPositions)
        }
    }
}
