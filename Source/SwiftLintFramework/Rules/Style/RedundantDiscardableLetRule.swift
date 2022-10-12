import SwiftSyntax

public struct RedundantDiscardableLetRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_discardable_let",
        name: "Redundant Discardable Let",
        description: "Prefer `_ = foo()` over `let _ = foo()` when discarding a result from a function.",
        kind: .style,
        nonTriggeringExamples: [
            Example("_ = foo()\n"),
            Example("if let _ = foo() { }\n"),
            Example("guard let _ = foo() else { return }\n"),
            Example("let _: ExplicitType = foo()"),
            Example("while let _ = SplashStyle(rawValue: maxValue) { maxValue += 1 }\n"),
            Example("async let _ = await foo()")
        ],
        triggeringExamples: [
            Example("↓let _ = foo()\n"),
            Example("if _ = foo() { ↓let _ = bar() }\n")
        ],
        corrections: [
            Example("↓let _ = foo()\n"): Example("_ = foo()\n"),
            Example("if _ = foo() { ↓let _ = bar() }\n"): Example("if _ = foo() { _ = bar() }\n")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension RedundantDiscardableLetRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.hasRedundantDiscardableLetViolation {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard node.hasRedundantDiscardableLetViolation, !isInDisabledRegion(node) else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let newNode = node
                .withLetOrVarKeyword(nil)
                .withBindings(node.bindings.withLeadingTrivia(node.letOrVarKeyword.leadingTrivia))
            return super.visit(newNode)
        }

        private func isInDisabledRegion<T: SyntaxProtocol>(_ node: T) -> Bool {
            disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }
        }
    }
}

private extension VariableDeclSyntax {
    var hasRedundantDiscardableLetViolation: Bool {
        letOrVarKeyword.tokenKind == .letKeyword &&
            bindings.count == 1 &&
            bindings.first!.pattern.is(WildcardPatternSyntax.self) &&
            bindings.first!.typeAnnotation == nil &&
            modifiers?.contains(where: { $0.name.text == "async" }) != true
    }
}
