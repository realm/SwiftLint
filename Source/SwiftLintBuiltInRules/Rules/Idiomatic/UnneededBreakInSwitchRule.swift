import SwiftSyntax

private func embedInSwitch(
    _ text: String,
    case: String = "case .bar",
    file: StaticString = #filePath,
    line: UInt = #line) -> Example {
    Example("""
        switch foo {
        \(`case`):
            \(text)
        }
        """, file: file, line: line)
}

@SwiftSyntaxRule(explicitRewriter: true)
struct UnneededBreakInSwitchRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

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
            """),
        ],
        triggeringExamples: [
            embedInSwitch("something()\n    ↓break"),
            embedInSwitch("something()\n    ↓break // comment"),
            embedInSwitch("something()\n    ↓break", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition"),
        ],
        corrections: [
            embedInSwitch("something()\n    ↓break")
            : embedInSwitch("something()"),
            embedInSwitch("something()\n    ↓break // line comment")
            : embedInSwitch("something()\n     // line comment"),
            embedInSwitch("""
                something()
                ↓break
                /*
                block comment
                */
                """)
            : embedInSwitch("""
                something()
                /*
                block comment
                */
                """),
            embedInSwitch("something()\n    ↓break /// doc line comment")
            : embedInSwitch("something()\n     /// doc line comment"),
            embedInSwitch("""
                something()
                ↓break
                ///
                /// doc block comment
                ///
                """)
            : embedInSwitch("""
                something()
                ///
                /// doc block comment
                ///
                """),
            embedInSwitch("something()\n    ↓break", case: "default")
            : embedInSwitch("something()", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition")
            : embedInSwitch("something()", case: "case .foo, .foo2 where condition"),
        ]
    )
}

private extension UnneededBreakInSwitchRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SwitchCaseSyntax) {
            guard let statement = node.unneededBreak else {
                return
            }

            violations.append(statement.item.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
            let stmts = CodeBlockItemListSyntax(node.statements.dropLast())

            guard let breakStatement = node.unneededBreak, let secondLast = stmts.last else {
                return super.visit(node)
            }

            correctionPositions.append(breakStatement.item.positionAfterSkippingLeadingTrivia)

            let trivia = breakStatement.item.leadingTrivia + breakStatement.item.trailingTrivia

            let newNode = node
                .with(\.statements, stmts)
                .with(\.statements.trailingTrivia, secondLast.item.trailingTrivia + trivia)
                .trimmed { !$0.isComment }
                .formatted()
                .as(SwitchCaseSyntax.self)!

            return super.visit(newNode)
        }
    }
}

private extension SwitchCaseSyntax {
    var unneededBreak: CodeBlockItemSyntax? {
        guard statements.count > 1,
              let breakStatement = statements.last?.item.as(BreakStmtSyntax.self),
              breakStatement.label == nil else {
            return nil
        }

        return statements.last
    }
}

private extension TriviaPiece {
    var isComment: Bool {
        switch self {
        case .lineComment, .blockComment, .docLineComment, .docBlockComment:
            return true
        default:
            return false
        }
    }
}
