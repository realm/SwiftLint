import SwiftSyntax

public struct ProtocolPropertyAccessorsOrderRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            Rewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

private extension ProtocolPropertyAccessorsOrderRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: AccessorBlockSyntax) {
            guard node.hasViolation else {
                return
            }

            violationPositions.append(node.accessors.positionAfterSkippingLeadingTrivia)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
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

        override func visit(_ node: AccessorBlockSyntax) -> Syntax {
            guard node.hasViolation else {
                return super.visit(node)
            }

            let isInDisabledRegion = disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }

            guard !isInDisabledRegion else {
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
