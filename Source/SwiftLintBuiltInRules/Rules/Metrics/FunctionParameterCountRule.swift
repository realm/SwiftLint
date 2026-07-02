import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct FunctionParameterCountRule: Rule {
    var configuration = FunctionParameterCountConfiguration()

    static let description = RuleDescription(
        identifier: "function_parameter_count",
        name: "Function Parameter Count",
        description: "Number of function parameters should be low.",
        kind: .metrics,
        nonTriggeringExamples: #examples([
            "init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init (a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "`init`(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init?(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init?<T>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "init?<T: String>(a: T, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "func f2(p1: Int, p2: Int) { }",
            "func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}",
            """
            func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {
                let s = a.flatMap { $0 as? [String: Int] } ?? []}}
            """,
            "override func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
        ]),
        triggeringExamples: #examples([
            "↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "↓func initialValue(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "private ↓func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}",
            """
            struct Foo {
                init(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}
                ↓func bar(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}}
            """,
        ])
    )
}

private extension FunctionParameterCountRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard !node.modifiers.contains(keyword: .override) else {
                return
            }

            let parameterList = node.signature.parameterClause.parameters
            guard let minThreshold = configuration.severityConfiguration.params.map(\.value).min(by: <) else {
                return
            }

            let allParameterCount = parameterList.count
            if allParameterCount < minThreshold {
                return
            }

            var parameterCount = allParameterCount
            if configuration.ignoresDefaultParameters {
                parameterCount -= parameterList.filter { $0.defaultValue != nil }.count
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
