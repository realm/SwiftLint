import SwiftSyntax

struct ProtocolPropertyAccessorsOrderRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "protocol_property_accessors_order",
        name: "Protocol Property Accessors Order",
        description: "When declaring properties in protocols, the order of accessors should be `get set`.",
        kind: .style,
        nonTriggeringExamples: [
            Example("protocol Foo {\n var bar: String { get set }\n }"),
            Example("protocol Foo {\n var bar: String { get }\n }"),
            Example("protocol Foo {\n var bar: String { set }\n }")
        ],
        triggeringExamples: [
            Example("protocol Foo {\n var bar: String { ↓set get }\n }")
        ],
        corrections: [
            Example("protocol Foo {\n var bar: String { ↓set get }\n }"):
                Example("protocol Foo {\n var bar: String { get set }\n }")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension ProtocolPropertyAccessorsOrderRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            .allExcept(ProtocolDeclSyntax.self, VariableDeclSyntax.self)
        }

        override func visitPost(_ node: AccessorBlockSyntax) {
            guard node.hasViolation else {
                return
            }

            violations.append(node.accessors.positionAfterSkippingLeadingTrivia)
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
            guard
                node.hasViolation,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.accessors.positionAfterSkippingLeadingTrivia)

            let reversedAccessors = AccessorListSyntax(Array(node.accessors.reversed()))
            return super.visit(
                node.withAccessors(reversedAccessors)
            )
        }
    }
}

private extension AccessorBlockSyntax {
    var hasViolation: Bool {
        guard accessors.count == 2,
              accessors.allSatisfy({ $0.body == nil }),
              accessors.first?.accessorKind.tokenKind == .contextualKeyword("set") else {
            return false
        }

        return true
    }
}
