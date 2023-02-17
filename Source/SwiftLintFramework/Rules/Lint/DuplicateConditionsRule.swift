import SwiftSyntax

struct DuplicateConditionsRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "duplicate_conditions",
        name: "Duplicate Conditions",
        description: "Duplicate conditions in the same branching statement should be avoided",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                if x < 5 {
                  foo()
                } else if y == "s" {
                  bar()
                }
            """),
            Example("""
                if x < 5 {
                  foo()
                }
                if x < 5 {
                  bar()
                }
            """),
            Example("""
                switch x {
                case \"a\":
                  foo()
                  bar()
                }
            """),
            Example("""
                if let x = maybeAbc {
                  foo()
                } else if let x = maybePqr {
                  bar()
                }
            """),
            Example("""
                if case .p = x {
                  foo()
                } else if case .q = x {
                  bar()
                }
            """)
        ],
        triggeringExamples: [
            Example("""
                if ↓x < 5 {
                  foo()
                } else if y == "s" {
                  bar()
                } else if ↓x < 5 { 
                  baz()
                }
            """),
            Example("""
                if x < 5, ↓y == "s" {
                  foo()
                } else if x < 10 {
                  bar()
                } else if ↓y == "s", x < 15 {
                  baz()
                }
            """),
            Example("""
                switch x {
                case ↓\"a\", \"b\":
                  foo()
                case \"c\", ↓\"a\":
                  bar()
                }
            """),
            Example("""
                if ↓let xyz = maybeXyz {
                  foo()
                } else if ↓let xyz = maybeXyz {
                  bar()
                }
            """),
            Example("""
                if ↓#available(macOS 10.15, *) {
                  foo()
                } else if ↓#available(macOS 10.15, *) {
                  bar()
                }
            """),
            Example("""
                if ↓case .p = x {
                  foo()
                } else if ↓case .p = x {
                  bar()
                }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DuplicateConditionsRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: IfStmtSyntax) {
            if let prevToken = node.previousToken,
               prevToken.tokenKind == .elseKeyword {
                // We can skip these cases - they will be picked up when we visit the top level `if`
                return
            }

            var maybeCurr: IfStmtSyntax? = node
            var statementChain: [IfStmtSyntax] = []
            while let curr = maybeCurr {
                statementChain.append(curr)
                maybeCurr = curr.elseBody?.as(IfStmtSyntax.self)
            }

            let positionsByCondition = statementChain
                .flatMap { $0.conditions }
                .compactMap(extract)
                .reduce(into: [[UInt8]: [AbsolutePosition]](), { xs, x in
                    xs[x.text, default: []].append(x.location)
                })

            addViolations(positionsByCondition)
        }

        override func visitPost(_ node: SwitchCaseListSyntax) {
            let switchCases = node.compactMap { $0.as(SwitchCaseSyntax.self) }

            let positionsByCondition = switchCases
                .reduce(into: [[UInt8]: [AbsolutePosition]]()) { xs, x in
                    // Defaults don't have a condition to worry about
                    guard case let .case(caseLabel) = x.label else { return }
                    for item in caseLabel.caseItems {
                        let pattern = item.pattern.withoutTrivia().syntaxTextBytes
                        let location = item.positionAfterSkippingLeadingTrivia
                        xs[pattern, default: []].append(location)
                    }
                }

            addViolations(positionsByCondition)
        }

        private func extract(_ node: ConditionElementSyntax) -> (text: [UInt8], location: AbsolutePosition)? {
            let text: [UInt8]
            switch node.condition {
            case .availability(let node):
                text = node.withoutTrivia().syntaxTextBytes
            case .expression(let node):
                text = node.withoutTrivia().syntaxTextBytes
            case .matchingPattern(let node):
                text = node.withoutTrivia().syntaxTextBytes
            case .optionalBinding(let node):
                text = node.withoutTrivia().syntaxTextBytes
            default:
                return nil
            }

            return (text: text, location: node.positionAfterSkippingLeadingTrivia)
        }

        private func addViolations(_ positionsByCondition: [[UInt8]: [AbsolutePosition]]) {
            let duplicatedPositions = positionsByCondition
                .filter { $0.value.count > 1 }
                .flatMap { $0.value }

            violations.append(contentsOf: duplicatedPositions)
        }
    }
}
