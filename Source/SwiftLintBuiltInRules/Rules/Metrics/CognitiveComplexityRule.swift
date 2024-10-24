import Foundation
import SwiftSyntax

@SwiftSyntaxRule
struct CognitiveComplexityRule: Rule {
    var configuration = CognitiveComplexityConfiguration()

    static let description = RuleDescription(
        identifier: "cognitive_complexity",
        name: "Cognitive Complexity",
        description: "Cognitive complexity of function bodies should be limited.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example("""
            func f1(count: Int, buffer: [Int]) -> Int {
                if count == 0
                    || buffer.count = 0 {
                    return 0
                }
                var sum = 0
                for index in 0..<buffer.count {
                    if buffer[index] > 0
                        && buffer[index] <= 10 {
                        if buffer.count > 10 {
                            if buffer[index] % 2 == 0 {
                                sum += buffer[index]
                            } else if sum > 0 {
                                sum -= buffer[index]
                            }
                        }
                    }
                }
                if sum < 0 {
                    return -sum
                }
                return sum
            }
            """),
            Example("""
            func f2(count: Int, buffer: [Int]) -> Int {
                var sum = 0
                for index in 0..<buffer.count {
                    if buffer[index] > 0 && buffer[index] <= 10 {
                        if buffer.count > 10 {
                            switch buffer[index] % 2 {
                            case 0:
                                if sum > 0 {
                                    sum += buffer[index]
                                }
                            default:
                                if sum > 0 {
                                    sum -= buffer[index]
                                }
                            }
                        }
                    }
                }
                return sum
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            func f3(count: Int, buffer: [Int]) -> Int {
                guard count > 0,
                    buffer.count > 0 {
                    return 0
                }
                var sum = 0
                for index in 0..<buffer.count {
                    if buffer[index] > 0
                        && buffer[index] <= 10 {
                        if buffer.count > 10 {
                            if buffer[index] % 2 == 0 {
                                sum += buffer[index]
                            } else if sum > 0 {
                                sum -= buffer[index]
                            } else if sum < 0 {
                                sum += buffer[index]
                            }
                        }
                    }
                }
                if sum < 0 {
                    return -sum
                }
                return sum
            }
            """),
        ]
    )
}

private extension CognitiveComplexityRule {
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
                ignoresLogicalOperatorSequences: configuration.ignoresLogicalOperatorSequences
            ).walk(tree: body, handler: \.complexity)

            for parameter in configuration.params where complexity > parameter.value {
                let reason = "Function should have cognitive complexity \(configuration.length.warning) or less; " +
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
        private let ignoresLogicalOperatorSequences: Bool
        private(set) var complexity = 0
        private var nesting = 0

        init(ignoresLogicalOperatorSequences: Bool) {
            self.ignoresLogicalOperatorSequences = ignoresLogicalOperatorSequences
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_: ForStmtSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_: ForStmtSyntax) {
            nesting -= 1
            complexity += nesting + 1
        }

        override func visit(_: IfExprSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_ node: IfExprSyntax) {
            nesting -= 1
            let nesting = node.parent?.as(IfExprSyntax.self)?.elseBody?.is(IfExprSyntax.self) == true ? 0 : nesting
            if ignoresLogicalOperatorSequences {
                complexity += nesting + 1
            } else {
                complexity += nesting + node.conditions.sequenceCount
            }
        }

        override func visit(_: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            nesting -= 1
            if ignoresLogicalOperatorSequences {
                complexity += nesting + 1
            } else {
                complexity += nesting + node.conditions.sequenceCount
            }
        }

        override func visit(_: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_: RepeatStmtSyntax) {
            nesting -= 1
            complexity += nesting + 1
        }

        override func visit(_: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_: WhileStmtSyntax) {
            nesting -= 1
            complexity += nesting + 1
        }

        override func visit(_: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_: CatchClauseSyntax) {
            nesting -= 1
            complexity += nesting + 1
        }

        override func visitPost(_: SwitchExprSyntax) {
            complexity += 1
        }

        override func visitPost(_: TernaryExprSyntax) {
            complexity += 1
        }

        override func visitPost(_ node: BreakStmtSyntax) {
            if node.label != nil {
                complexity += 1
            }
        }

        override func visitPost(_ node: ContinueStmtSyntax) {
            if node.label != nil {
                complexity += 1
            }
        }

        override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_: FunctionDeclSyntax) {
            nesting -= 1
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            nesting += 1
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            nesting -= 1
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

private extension ConditionElementListSyntax {
    var sequenceCount: Int {
        description.components(separatedBy: .newlines).count
    }
}
