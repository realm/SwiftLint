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
            let violationToken = node.modifiers.first { element in
                let kind = element.name.tokenKind
                return kind == .keyword(.static) || kind == .keyword(.class)
            }?.name
                ?? node.funcKeyword
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
}

private extension ConditionElementListSyntax {
    var sequenceCount: Int {
        description.components(separatedBy: .newlines).count
    }
}

class ComplexityVisitor: SyntaxVisitor {
    private let ignoresLogicalOperatorSequences: Bool
    private(set) var complexity = 0
    private var nesting = 0

    init(ignoresLogicalOperatorSequences: Bool) {
        self.ignoresLogicalOperatorSequences = ignoresLogicalOperatorSequences
        super.init(viewMode: .sourceAccurate)
    }

    func enterNode(_ baseCost: Int? = nil, nesting nestingCost: Int? = nil, other otherCost: Int? = nil) -> SyntaxVisitorContinueKind {
        self.complexity += (baseCost ?? 1)
                        + (nestingCost ?? self.nesting)
                        + (otherCost ?? 0)
        self.nesting += 1
        return .visitChildren
    }

    // if

    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        let baseCost = ignoresLogicalOperatorSequences ? 1 : node.conditions.sequenceCount

        // Only penalize the initial `if`, not the `if else`
        let nestingCost = node.parent?
            .as(IfExprSyntax.self)?
            .elseBody?
            .is(IfExprSyntax.self) == true
        ? 0 : nesting

        let elseCost = node.elseBody != nil
        && !node.elseBody!.is(IfExprSyntax.self)
        ? 1 : 0

        return enterNode(baseCost, nesting: nestingCost, other: elseCost)
    }

    override func visitPost(_: IfExprSyntax) { nesting -= 1 }

    // guard

    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        let baseCost = ignoresLogicalOperatorSequences ? 1 : node.conditions.sequenceCount

        return enterNode(baseCost)
    }

    override func visitPost(_: GuardStmtSyntax) {        nesting -= 1    }

    // ternary

    override func visit(_: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
        enterNode()
    }

    override func visitPost(_: TernaryExprSyntax) { nesting -= 1 }

    // switch

    override func visit(_: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        enterNode()
    }

    override func visitPost(_: SwitchExprSyntax) { nesting -= 1 }

    // for

    override func visit(_: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        enterNode()
    }

    override func visitPost(_: ForStmtSyntax) { nesting -= 1 }

    // while

    override func visit(_: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        enterNode()
    }

    override func visitPost(_: WhileStmtSyntax) { nesting -= 1 }

    // repeat

    override func visit(_: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        enterNode()
    }

    override func visitPost(_: RepeatStmtSyntax) { nesting -= 1 }

    // catch

    override func visit(_: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        enterNode()
    }

    override func visitPost(_: CatchClauseSyntax) { nesting -= 1 }

    // break & continue

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

    // closures

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        // Only increment nesting
        enterNode(0, nesting: 0)
    }

    override func visitPost(_: ClosureExprSyntax) { nesting -= 1 }
}
