import SwiftSyntax

struct EmptyParametersRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "empty_parameters",
        name: "Empty Parameters",
        description: "Prefer `() -> ` over `Void -> `.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let abc: () -> Void = {}\n"),
            Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: () throws -> Void)\n"),
            Example("let foo: (ConfigurationTests) -> Void throws -> Void)\n"),
            Example("let foo: (ConfigurationTests) ->   Void throws -> Void)\n"),
            Example("let foo: (ConfigurationTests) ->Void throws -> Void)\n")
        ],
        triggeringExamples: [
            Example("let abc: ↓(Void) -> Void = {}\n"),
            Example("func foo(completion: ↓(Void) -> Void)\n"),
            Example("func foo(completion: ↓(Void) throws -> Void)\n"),
            Example("let foo: ↓(Void) -> () throws -> Void)\n")
        ],
        corrections: [
            Example("let abc: ↓(Void) -> Void = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("func foo(completion: ↓(Void) -> Void)\n"): Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: ↓(Void) throws -> Void)\n"):
                Example("func foo(completion: () throws -> Void)\n"),
            Example("let foo: ↓(Void) -> () throws -> Void)\n"): Example("let foo: () -> () throws -> Void)\n")
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

private extension EmptyParametersRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionTypeSyntax) {
            guard let violationPosition = node.emptyParametersViolationPosition else {
                return
            }

            violations.append(violationPosition)
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

        override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
            guard
                let violationPosition = node.emptyParametersViolationPosition,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(violationPosition)
            return super.visit(node.withArguments(TupleTypeElementListSyntax([])))
        }
    }
}

private extension FunctionTypeSyntax {
    var emptyParametersViolationPosition: AbsolutePosition? {
        guard
            let argument = arguments.onlyElement,
            leftParen.presence == .present,
            rightParen.presence == .present,
            let simpleType = argument.type.as(SimpleTypeIdentifierSyntax.self),
            simpleType.typeName == "Void"
        else {
            return nil
        }

        return leftParen.positionAfterSkippingLeadingTrivia
    }
}
