import Foundation
import SwiftSyntax

public struct VoidReturnRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let abc: () -> Void = {}\n"),
            Example("let abc: () -> (VoidVoid) = {}\n"),
            Example("func foo(completion: () -> Void)\n"),
            Example("let foo: (ConfigurationTests) -> () throws -> Void\n"),
            Example("let foo: (ConfigurationTests) ->   () throws -> Void\n"),
            Example("let foo: (ConfigurationTests) ->() throws -> Void\n"),
            Example("let foo: (ConfigurationTests) -> () -> Void\n")
        ],
        triggeringExamples: [
            Example("let abc: () -> ↓() = {}\n"),
            Example("let abc: () -> ↓(Void) = {}\n"),
            Example("let abc: () -> ↓(   Void ) = {}\n"),
            Example("func foo(completion: () -> ↓())\n"),
            Example("func foo(completion: () -> ↓(   ))\n"),
            Example("func foo(completion: () -> ↓(Void))\n"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()\n")
        ],
        corrections: [
            Example("let abc: () -> ↓() = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("let abc: () -> ↓(Void) = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("let abc: () -> ↓(   Void ) = {}\n"): Example("let abc: () -> Void = {}\n"),
            Example("func foo(completion: () -> ↓())\n"): Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: () -> ↓(   ))\n"): Example("func foo(completion: () -> Void)\n"),
            Example("func foo(completion: () -> ↓(Void))\n"): Example("func foo(completion: () -> Void)\n"),
            Example("let foo: (ConfigurationTests) -> () throws -> ↓()\n"):
                Example("let foo: (ConfigurationTests) -> () throws -> Void\n")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        VoidReturnRuleVisitor()
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            VoidReturnRuleRewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

// MARK: - VoidReturnRuleVisitor

private final class VoidReturnRuleVisitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []

    override func visitPost(_ node: FunctionTypeSyntax) {
        guard let tuple = node.returnType.as(TupleTypeSyntax.self),
              tuple.shouldReturnVoid else {
            return
        }

        violationPositions.append(tuple.positionAfterSkippingLeadingTrivia)
    }
}

private extension TupleTypeSyntax {
    var shouldReturnVoid: Bool {
        if elements.isEmpty {
            return true
        }

        if elements.count == 1,
           let identifier = elements.first?.type.as(SimpleTypeIdentifierSyntax.self),
           identifier.name.text == "Void" {
            return true
        }

        return false
    }
}

// MARK: - VoidReturnRuleRewriter

private final class VoidReturnRuleRewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [AbsolutePosition] = []
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        guard let tuple = node.returnType.as(TupleTypeSyntax.self),
              tuple.shouldReturnVoid else {
            return super.visit(node)
        }

        let isInDisabledRegion = disabledRegions.contains { region in
            region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
        }

        guard !isInDisabledRegion else {
            return super.visit(node)
        }

        correctionPositions.append(tuple.positionAfterSkippingLeadingTrivia)

        var returnType = SyntaxFactory.makeTypeIdentifier("Void")
        returnType.leadingTrivia = tuple.leadingTrivia
        returnType.trailingTrivia = tuple.trailingTrivia

        return super.visit(node.withReturnType(returnType))
    }
}
