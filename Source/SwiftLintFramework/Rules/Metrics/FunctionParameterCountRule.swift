import SwiftSyntax

struct FunctionParameterCountRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = FunctionParameterCountConfiguration(warning: 5, error: 8)

    init() {}

    static let description = RuleDescription(
        identifier: "function_parameter_count",
        name: "Function Parameter Count",
        description: "Number of function parameters should be low.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init (a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init?<T>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("init?<T: String>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("func f2(p1: Int, p2: Int) { }"),
            Example("func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}"),
            Example("""
            func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {
                let s = a.flatMap { $0 as? [String: Int] } ?? []}}
            """),
            Example("override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}")
        ],
        triggeringExamples: [
            Example("↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("↓func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}"),
            Example("private ↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}"),
            Example("""
            struct Foo {
                init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
                ↓func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(configuration: configuration)
    }
}

private extension FunctionParameterCountRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let configuration: FunctionParameterCountConfiguration

        init(configuration: FunctionParameterCountConfiguration) {
            self.configuration = configuration
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard !node.modifiers.containsOverride else {
                return
            }

            let parameterList = node.signature.input.parameterList
            guard let minThreshold = configuration.severityConfiguration.params.map(\.value).min(by: <) else {
                return
            }

            let allParameterCount = parameterList.count
            if allParameterCount < minThreshold {
                return
            }

            var parameterCount = allParameterCount
            if configuration.ignoresDefaultParameters {
                parameterCount -= parameterList.filter { $0.defaultArgument != nil }.count
            }

            for parameter in configuration.severityConfiguration.params where parameterCount > parameter.value {
                let reason = "Function should have \(configuration.severityConfiguration.warning) parameters " +
                             "or less: it currently has \(parameterCount)"

                violations.append(
                    ReasonedRuleViolation(
                        position: node.funcKeyword.positionAfterSkippingLeadingTrivia,
                        reason: reason,
                        severity: parameter.severity
                    )
                )
                return
            }
        }
    }
}
