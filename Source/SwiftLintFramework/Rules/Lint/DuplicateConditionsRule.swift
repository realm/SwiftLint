import SwiftSyntax

struct DuplicateConditionsRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.error)

    init() {}

    static let description = RuleDescription(
        identifier: "duplicate_conditions",
        name: "Duplicate Conditions",
        description: "Duplicate sets of conditions in the same branch instruction should be avoided",
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
                if x < 5, y == "s" {
                  foo()
                } else if x < 5 {
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
                switch x {
                case \"a\" where y == "s":
                  foo()
                case \"a\" where y == "t":
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
                if let x = maybeAbc, let z = x.maybeY {
                  foo()
                } else if let x = maybePqr, let z = x.maybeY {
                  bar()
                }
            """),
            Example("""
                if case .p = x {
                  foo()
                } else if case .q = x {
                  bar()
                }
            """),
            Example("""
                if true {
                  if true { foo() }
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
                if z {
                  if ↓x < 5 {
                    foo()
                  } else if y == "s" {
                    bar()
                  } else if ↓x < 5 {
                    baz()
                  }
                }
            """),
            Example("""
                if ↓x < 5, y == "s" {
                  foo()
                } else if x < 10 {
                  bar()
                } else if ↓y == "s", x < 5 {
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
                switch x {
                case ↓\"a\" where y == "s":
                  foo()
                case ↓\"a\" where y == "s":
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
                if ↓let x = maybeAbc, let z = x.maybeY {
                  foo()
                } else if ↓let x = maybeAbc, let z = x.maybeY {
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
            """),
            Example("""
                if ↓x < 5 {}
                else if ↓x < 5 {}
                else if ↓x < 5 {}
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension DuplicateConditionsRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: IfExprSyntax) {
            if  node.parent?.is(IfExprSyntax.self) == true {
                // We can skip these cases - they will be picked up when we visit the top level `if`
                return
            }

            var maybeCurr: IfExprSyntax? = node
            var statementChain: [IfExprSyntax] = []
            while let curr = maybeCurr {
                statementChain.append(curr)
                maybeCurr = curr.elseBody?.as(IfExprSyntax.self)
            }

            let positionsByConditions = statementChain
                .reduce(into: [Set<String>: [AbsolutePosition]]()) { acc, elt in
                    let conditions = elt.conditions.map {
                        $0.condition.debugDescription(includeChildren: true, includeTrivia: false)
                    }
                    let location = elt.conditions.positionAfterSkippingLeadingTrivia
                    acc[Set(conditions), default: []].append(location)
                }

            addViolations(Array(positionsByConditions.values))
        }

        override func visitPost(_ node: SwitchCaseListSyntax) {
            let switchCases = node.compactMap { $0.as(SwitchCaseSyntax.self) }

            let positionsByCondition = switchCases
                .reduce(into: [String: [AbsolutePosition]]()) { acc, elt in
                    // Defaults don't have a condition to worry about
                    guard case let .case(caseLabel) = elt.label else { return }
                    for caseItem in caseLabel.caseItems {
                        let pattern = caseItem
                            .pattern
                            .debugDescription(includeChildren: true, includeTrivia: false)
                        let whereClause = caseItem
                            .whereClause?
                            .debugDescription(includeChildren: true, includeTrivia: false)
                            ?? ""
                        let location = caseItem.positionAfterSkippingLeadingTrivia
                        acc[pattern + whereClause, default: []].append(location)
                    }
                }

            addViolations(Array(positionsByCondition.values))
        }

        private func addViolations(_ positionsByCondition: [[AbsolutePosition]]) {
            let duplicatedPositions = positionsByCondition
                .filter { $0.count > 1 }
                .flatMap { $0 }

            violations.append(contentsOf: duplicatedPositions)
        }
    }
}
