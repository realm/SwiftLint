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
                case 1: return 1
                case 2: return 1
                case 3: return 1
                case 4: return 1
                case 5: return 1
                case 6: return 1
                case 7: return 1
                case 8: return 1
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
            """),
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
            """),
        ]
    )
}

private extension CyclomaticComplexityRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let body = node.body else {
                return
            }

            // for legacy reasons, we try to put the violation in the static or class keyword
            let violationToken = node.modifiers.staticOrClassModifier ?? node.funcKeyword
            validate(body: body, violationToken: violationToken)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            guard let body = node.body else {
                return
            }

            validate(body: body, violationToken: node.initKeyword)
        }

        private func validate(body: CodeBlockSyntax, violationToken: TokenSyntax) {
            let complexity = ComplexityVisitor(
                ignoresCaseStatements: configuration.ignoresCaseStatements
            ).walk(tree: body, handler: \.complexity)

            for parameter in configuration.params where complexity > parameter.value {
                let reason = "Function should have complexity \(configuration.length.warning) or less; " +
                             "currently complexity is \(complexity)"

                let violation = ReasonedRuleViolation(
                    position: violationToken.positionAfterSkippingLeadingTrivia,
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

        override func visitPost(_: ForStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_: IfExprSyntax) {
            complexity += 1
        }

        override func visitPost(_: GuardStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_: RepeatStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_: WhileStmtSyntax) {
            complexity += 1
        }

        override func visitPost(_: CatchClauseSyntax) {
            complexity += 1
        }

        override func visitPost(_: SwitchCaseSyntax) {
            if !ignoresCaseStatements {
                complexity += 1
            }
        }

        override func visitPost(_: FallThroughStmtSyntax) {
            // Switch complexity is reduced by `fallthrough` cases
            if !ignoresCaseStatements {
                complexity -= 1
            }
        }

        override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}

private extension DeclModifierListSyntax {
    var staticOrClassModifier: TokenSyntax? {
        first { element in
            let kind = element.name.tokenKind
            return kind == .keyword(.static) || kind == .keyword(.class)
        }?.name
    }
}
