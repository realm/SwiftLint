import Foundation
import SwiftSyntax

@SwiftSyntaxRule
struct CyclomaticComplexityRule: Rule {
    var configuration = CyclomaticComplexityConfiguration()

    static let description = RuleDescription(
        identifier: "cyclomatic_complexity",
        name: "Cyclomatic Complexity",
        description: "Complexity of function bodies should be limited.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("""
            func f1() {
                if true {
                    for _ in 1..5 { }
                }
                if false { }
            }
            """),
            Example("""
            func f(code: Int) -> Int {
                switch code {
                case 0: fallthrough
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                case 0: return 1
                default: return 1
                }
            }
            """),
            Example("""
            func f1() {
                if true {}; if true {}; if true {}; if true {}; if true {}; if true {}
                func f2() {
                    if true {}; if true {}; if true {}; if true {}; if true {}
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓func f1() {
                if true {
                    if true {
                        if false {}
                    }
                }
                if false {}
                let i = 0
                switch i {
                    case 1: break
                    case 2: break
                    case 3: break
                    case 4: break
                    default: break
                }
                for _ in 1...5 {
                    guard true else {
                        return
                    }
                }
            }
            """)
        ]
    )
}

private extension CyclomaticComplexityRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }

            let complexity = ComplexityVisitor(
                ignoresCaseStatements: configuration.ignoresCaseStatements
            ).walk(tree: body, handler: \.complexity)

            for parameter in configuration.params where complexity > parameter.value {
                let reason = "Function should have complexity \(configuration.length.warning) or less; " +
                             "currently complexity is \(complexity)"

                let violation = ReasonedRuleViolation(
                    position: node.funcKeyword.positionAfterSkippingLeadingTrivia,
                    reason: reason,
                    severity: parameter.severity
                )
                violations.append(violation)
                return
            }
        }
    }

    private class ComplexityVisitor: SyntaxVisitor {
        private(set) var complexity = 0
        let ignoresCaseStatements: Bool

        init(ignoresCaseStatements: Bool) {
            self.ignoresCaseStatements = ignoresCaseStatements
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ForStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_ node: IfExprSyntax) {
            complexity += 1
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_ node: RepeatStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_ node: SwitchCaseSyntax) {
            if !ignoresCaseStatements {
                complexity += 1
            }
        }

        override func visitPost(_ node: FallThroughStmtSyntax) {
            // Switch complexity is reduced by `fallthrough` cases
            if !ignoresCaseStatements {
                complexity -= 1
            }
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}
