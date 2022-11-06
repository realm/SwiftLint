import SwiftSyntax

private func embedInSwitch(
    _ text: String,
    case: String = "case .bar",
    file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
        switch foo {
        \(`case`):
            \(text)
        }
        """, file: file, line: line)
}

struct UnneededBreakInSwitchRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "unneeded_break_in_switch",
        name: "Unneeded Break in Switch",
        description: "Avoid using unneeded break statements",
        kind: .idiomatic,
        nonTriggeringExamples: [
            embedInSwitch("break"),
            embedInSwitch("break", case: "default"),
            embedInSwitch("for i in [0, 1, 2] { break }"),
            embedInSwitch("if true { break }"),
            embedInSwitch("something()"),
            Example("""
            let items = [Int]()
            for item in items {
                if bar() {
                    do {
                        try foo()
                    } catch {
                        bar()
                        break
                    }
                }
            }
            """)
        ],
        triggeringExamples: [
            embedInSwitch("something()\n    ↓break"),
            embedInSwitch("something()\n    ↓break // comment"),
            embedInSwitch("something()\n    ↓break", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        UnneededBreakInSwitchRuleVisitor(viewMode: .sourceAccurate)
    }
}

private final class UnneededBreakInSwitchRuleVisitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: SwitchCaseSyntax) {
        guard node.statements.count > 1,
              let statement = node.statements.last,
              let breakStatement = statement.item.as(BreakStmtSyntax.self),
              breakStatement.label == nil else {
            return
        }

        violations.append(statement.item.positionAfterSkippingLeadingTrivia)
    }
}
