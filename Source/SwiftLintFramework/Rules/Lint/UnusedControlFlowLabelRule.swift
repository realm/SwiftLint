import SwiftSyntax

struct UnusedControlFlowLabelRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            """)
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
            """)
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
                """)
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

private extension UnusedControlFlowLabelRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: LabeledStmtSyntax) {
            if let position = node.violationPosition {
                violations.append(position)
            }
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

        override func visit(_ node: LabeledStmtSyntax) -> StmtSyntax {
            guard let violationPosition = node.violationPosition,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            let newNode = node.statement.with(\.leadingTrivia, node.leadingTrivia ?? .zero)
            correctionPositions.append(violationPosition)
            return visit(newNode).as(StmtSyntax.self) ?? newNode
        }
    }
}

private extension LabeledStmtSyntax {
    var violationPosition: AbsolutePosition? {
        let visitor = BreakAndContinueLabelCollector(viewMode: .sourceAccurate)
        let labels = visitor.walk(tree: self, handler: \.labels)
        guard !labels.contains(labelName.text) else {
            return nil
        }

        return labelName.positionAfterSkippingLeadingTrivia
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
