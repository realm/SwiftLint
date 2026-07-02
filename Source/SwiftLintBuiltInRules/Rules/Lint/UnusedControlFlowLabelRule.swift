import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct UnusedControlFlowLabelRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unused_control_flow_label",
        name: "Unused Control Flow Label",
        description: "Unused control flow label should be removed",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "loop: while true { break loop }",
            "loop: while true { continue loop }",
            "loop:\n    while true { break loop }",
            "while true { break }",
            "loop: for x in array { break loop }",
            """
            label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break label
            }
            """,
            """
            loop: repeat {
                if x == 10 {
                    break loop
                }
            } while true
            """,
        ]),
        triggeringExamples: #examples([
            "↓loop: while true { break }",
            "↓loop: while true { break loop1 }",
            "↓loop: while true { break outerLoop }",
            "↓loop: for x in array { break }",
            """
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """,
            """
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """,
        ]),
        corrections: #corrections([
            "↓loop: while true { break }": "while true { break }",
            "↓loop: while true { break loop1 }": "while true { break loop1 }",
            "↓loop: while true { break outerLoop }": "while true { break outerLoop }",
            "↓loop: for x in array { break }": "for x in array { break }",
            """
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """: """
                switch number {
                case 1: print("1")
                case 2: print("2")
                default: break
                }
                """,
            """
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """: """
                repeat {
                    if x == 10 {
                        break
                    }
                } while true
                """,
        ])
    )
}

private extension UnusedControlFlowLabelRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: LabeledStmtSyntax) {
            if let position = node.violationPosition {
                violations.append(position)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: LabeledStmtSyntax) -> StmtSyntax {
            guard node.violationPosition != nil else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return visit(node.statement.with(\.leadingTrivia, node.leadingTrivia))
        }
    }
}

private extension LabeledStmtSyntax {
    var violationPosition: AbsolutePosition? {
        let visitor = BreakAndContinueLabelCollector(viewMode: .sourceAccurate)
        let labels = visitor.walk(tree: self, handler: \.labels)
        guard !labels.contains(label.text) else {
            return nil
        }

        return label.positionAfterSkippingLeadingTrivia
    }
}

private class BreakAndContinueLabelCollector: SyntaxVisitor {
    private(set) var labels: Set<String> = []

    override func visitPost(_ node: BreakStmtSyntax) {
        if let label = node.label?.text {
            labels.insert(label)
        }
    }

    override func visitPost(_ node: ContinueStmtSyntax) {
        if let label = node.label?.text {
            labels.insert(label)
        }
    }
}
