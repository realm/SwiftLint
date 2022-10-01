import SwiftSyntax

public struct IfLetShadowingRule: OptInRule, SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public static var description = RuleDescription(
        identifier: "if_let_shadowing",
        name: "If-let Shadowing",
        description: "Use shorthand syntax for optional binding",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotSeven,
        nonTriggeringExamples: [
            Example("""
                if let i {}
                if let i = a {}
                guard let i = f() else {}
                if var i = i() {}
                if let i = i as? Foo {}
                guard let `self` = self else {}
                while var i { i = nil }
            """),
            Example("""
                if let i,
                   var i = a,
                   j > 0 {}
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("""
                if ↓let i = i {}
                if ↓let self = self {}
                if ↓var `self` = `self` {}
                if i > 0, ↓let j = j {}
                if ↓let i = i, ↓var j = j {}
            """),
            Example("""
                if ↓let i = i,
                   ↓var j = j,
                   j > 0 {}
            """, excludeFromDocumentation: true),
            Example("""
                guard ↓let i = i else {}
                guard ↓let self = self else {}
                guard ↓var `self` = `self` else {}
                guard i > 0, ↓let j = j else {}
                guard ↓let i = i, ↓var j = j else {}
            """),
            Example("""
                while ↓var i = i { i = nil }
            """)
        ],
        corrections: [
            Example("""
                if ↓let i = i {}
            """): Example("""
                if let i {}
            """),
            Example("""
                if ↓let self = self {}
            """): Example("""
                if let self {}
            """),
            Example("""
                if ↓var `self` = `self` {}
            """): Example("""
                if var `self` {}
            """),
            Example("""
                guard ↓let i = i, ↓var j = j  , ↓let k  =k else {}
            """): Example("""
                guard let i, var j  , let k else {}
            """),
            Example("""
                while j > 0, ↓var i = i   { i = nil }
            """): Example("""
                while j > 0, var i   { i = nil }
            """)
        ]
    )

    public init() {}

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

private class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []

    override func visitPost(_ node: OptionalBindingConditionSyntax) {
        if node.isShadowingOptionalBinding {
            violationPositions.append(node.letOrVarKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [AbsolutePosition] = []
    private let locationConverter: SourceLocationConverter
    private let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: OptionalBindingConditionSyntax) -> Syntax {
        guard node.isShadowingOptionalBinding else {
            return super.visit(node)
        }
        let isInDisabledRegion = disabledRegions.contains { region in
            region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
        }
        guard !isInDisabledRegion else {
            return super.visit(node)
        }
        correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
        let newNode = node
            .withInitializer(nil)
            .withPattern(node.pattern.withTrailingTrivia(node.trailingTrivia ?? .zero))
        return super.visit(newNode)
    }
}

private extension OptionalBindingConditionSyntax {
    var isShadowingOptionalBinding: Bool {
        if let id = pattern.as(IdentifierPatternSyntax.self),
           let value = initializer?.value.as(IdentifierExprSyntax.self),
           id.identifier.text == value.identifier.text {
            return true
        }
        return false
    }
}
