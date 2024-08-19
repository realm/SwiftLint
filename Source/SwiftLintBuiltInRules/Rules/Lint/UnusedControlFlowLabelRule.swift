import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct UnusedControlFlowLabelRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "unused_control_flow_label",
        name: "Unused Control Flow Label",
        description: "Unused control flow label should be removed",
        kind: .lint,
        nonTriggeringExamples: [
            Example("loop: while true { break loop }"),
            Example("loop: while true { continue loop }"),
            Example("loop:\n    while true { break loop }"),
            Example("while true { break }"),
            Example("loop: for x in array { break loop }"),
            Example("""
            label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break label
            }
            """),
            Example("""
            loop: repeat {
                if x == 10 {
                    break loop
                }
            } while true
            """),
        ],
        triggeringExamples: [
            Example("↓loop: while true { break }"),
            Example("↓loop: while true { break loop1 }"),
            Example("↓loop: while true { break outerLoop }"),
            Example("↓loop: for x in array { break }"),
            Example("""
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """),
            Example("""
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """),
        ],
        corrections: [
            Example("↓loop: while true { break }"): Example("while true { break }"),
            Example("↓loop: while true { break loop1 }"): Example("while true { break loop1 }"),
            Example("↓loop: while true { break outerLoop }"): Example("while true { break outerLoop }"),
            Example("↓loop: for x in array { break }"): Example("for x in array { break }"),
            Example("""
            ↓label: switch number {
            case 1: print("1")
            case 2: print("2")
            default: break
            }
            """): Example("""
                switch number {
                case 1: print("1")
                case 2: print("2")
                default: break
                }
                """),
            Example("""
            ↓loop: repeat {
                if x == 10 {
                    break
                }
            } while true
            """): Example("""
                repeat {
                    if x == 10 {
                        break
                    }
                } while true
                """),
        ]
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
            guard let violationPosition = node.violationPosition else {
                return super.visit(node)
            }
            correctionPositions.append(violationPosition)
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
