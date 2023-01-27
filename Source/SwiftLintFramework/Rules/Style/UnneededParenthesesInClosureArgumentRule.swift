import SwiftSyntax

struct UnneededParenthesesInClosureArgumentRule: ConfigurationProviderRule,
                                                        SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "unneeded_parentheses_in_closure_argument",
        name: "Unneeded Parentheses in Closure Argument",
        description: "Parentheses are not needed when declaring closure arguments",
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

private final class Visitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: ClosureSignatureSyntax) {
        guard let clause = node.input?.as(ParameterClauseSyntax.self),
              !clause.parameterList.contains(where: { $0.type != nil }),
              clause.parameterList.isNotEmpty else {
            return
        }

        violations.append(clause.positionAfterSkippingLeadingTrivia)
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

    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
        guard
            let clause = node.input?.as(ParameterClauseSyntax.self),
            !clause.parameterList.contains(where: { $0.type != nil }),
            clause.parameterList.isNotEmpty,
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
        else {
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

        let paramList = ClosureParamListSyntax(items).with(\.trailingTrivia, .spaces(1))
        return super.visit(node.with(\.input, .init(paramList)))
    }
}
