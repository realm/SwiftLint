import SwiftSyntax

public struct DuplicateEnumCasesRule: ConfigurationProviderRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "duplicate_enum_cases",
        name: "Duplicate Enum Cases",
        description: "Enum can't contain multiple cases with the same name.",
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DuplicateEnumCasesRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

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

            violationPositions.append(contentsOf: duplicatedElementPositions)
        }
    }
}
