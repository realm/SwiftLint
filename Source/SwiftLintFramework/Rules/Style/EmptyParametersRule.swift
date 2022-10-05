import SwiftSyntax

public struct EmptyParametersRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

private extension EmptyParametersRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionTypeSyntax) {
            guard let violationPosition = node.emptyParametersViolationPosition else {
                return
            }

            violationPositions.append(violationPosition)
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
                !isInDisabledRegion(node)
            else {
                return super.visit(node)
            }

            correctionPositions.append(violationPosition)
            return super.visit(node.withArguments(TupleTypeElementListSyntax([])))
        }

        private func isInDisabledRegion<T: SyntaxProtocol>(_ node: T) -> Bool {
            disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }
        }
    }
}

private extension FunctionTypeSyntax {
    var emptyParametersViolationPosition: AbsolutePosition? {
        guard
            arguments.count == 1,
            leftParen.presence == .present,
            rightParen.presence == .present,
            let argument = arguments.first,
            let simpleType = argument.type.as(SimpleTypeIdentifierSyntax.self),
            simpleType.typeName == "Void"
        else {
            return nil
        }

        return leftParen.positionAfterSkippingLeadingTrivia
    }
}
