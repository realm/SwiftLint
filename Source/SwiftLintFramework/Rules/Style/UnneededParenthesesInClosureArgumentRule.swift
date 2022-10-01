import SwiftSyntax

public struct UnneededParenthesesInClosureArgumentRule: ConfigurationProviderRule,
                                                        SwiftSyntaxCorrectableRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unneeded_parentheses_in_closure_argument",
        name: "Unneeded Parentheses in Closure Argument",
        description: "Parentheses are not needed when declaring closure arguments.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = { (bar: Int) in }\n"),
            Example("let foo = { bar, _  in }\n"),
            Example("let foo = { bar in }\n"),
            Example("let foo = { bar -> Bool in return true }\n"),
            Example("""
            DispatchQueue.main.async { () -> Void in
                doSomething()
            }
            """),
            Example("""
            registerFilter(name) { any, args throws -> Any? in
                doSomething(any, args)
            }
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("call(arg: { ↓(bar) in })\n"),
            Example("call(arg: { ↓(bar, _) in })\n"),
            Example("let foo = { ↓(bar) -> Bool in return true }\n"),
            Example("foo.map { ($0, $0) }.forEach { ↓(x, y) in }"),
            Example("foo.bar { [weak self] ↓(x, y) in }"),
            Example("""
            [].first { ↓(temp) in
                [].first { ↓(temp) in
                    [].first { ↓(temp) in
                        _ = temp
                        return false
                    }
                    return false
                }
                return false
            }
            """),
            Example("""
            [].first { temp in
                [].first { ↓(temp) in
                    [].first { ↓(temp) in
                        _ = temp
                        return false
                    }
                    return false
                }
                return false
            }
            """),
            Example("""
            registerFilter(name) { ↓(any, args) throws -> Any? in
                doSomething(any, args)
            }
            """, excludeFromDocumentation: true)
        ],
        corrections: [
            Example("call(arg: { ↓(bar) in })\n"): Example("call(arg: { bar in })\n"),
            Example("call(arg: { ↓(bar, _) in })\n"): Example("call(arg: { bar, _ in })\n"),
            Example("call(arg: { ↓(bar, _)in })\n"): Example("call(arg: { bar, _ in })\n"),
            Example("let foo = { ↓(bar) -> Bool in return true }\n"):
                Example("let foo = { bar -> Bool in return true }\n"),
            Example("method { ↓(foo, bar) in }\n"): Example("method { foo, bar in }\n"),
            Example("foo.map { ($0, $0) }.forEach { ↓(x, y) in }"): Example("foo.map { ($0, $0) }.forEach { x, y in }"),
            Example("foo.bar { [weak self] ↓(x, y) in }"): Example("foo.bar { [weak self] x, y in }")
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

private final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
    private(set) var violationPositions: [AbsolutePosition] = []

    override func visitPost(_ node: ClosureSignatureSyntax) {
        guard let clause = node.input?.as(ParameterClauseSyntax.self),
              !clause.parameterList.contains(where: { $0.type != nil }),
              clause.parameterList.isNotEmpty else {
            return
        }

        violationPositions.append(clause.positionAfterSkippingLeadingTrivia)
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

    override func visit(_ node: ClosureSignatureSyntax) -> Syntax {
        guard let clause = node.input?.as(ParameterClauseSyntax.self),
              !clause.parameterList.contains(where: { $0.type != nil }),
              clause.parameterList.isNotEmpty else {
            return super.visit(node)
        }

        let isInDisabledRegion = disabledRegions.contains { region in
            region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
        }

        guard !isInDisabledRegion else {
            return super.visit(node)
        }

        let items = clause.parameterList.enumerated().compactMap { idx, param -> ClosureParamSyntax? in
            guard let name = param.firstName else {
                return nil
            }

            let isLast = idx == clause.parameterList.count - 1
            return ClosureParamSyntax(
                name: name,
                trailingComma: isLast ? nil : .commaToken(trailingTrivia: Trivia(pieces: [.spaces(1)]))
            )
        }

        correctionPositions.append(clause.positionAfterSkippingLeadingTrivia)

        let paramList = ClosureParamListSyntax(items).withTrailingTrivia(.spaces(1))
        return super.visit(node.withInput(Syntax(paramList)))
    }
}
