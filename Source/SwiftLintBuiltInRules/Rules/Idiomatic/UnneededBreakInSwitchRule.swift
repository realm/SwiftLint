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

struct UnneededBreakInSwitchRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
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
            """)
        ],
        triggeringExamples: [
            embedInSwitch("something()\n    ↓break"),
            embedInSwitch("something()\n    ↓break // comment"),
            embedInSwitch("something()\n    ↓break", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition")
        ],
        corrections: [
            embedInSwitch("something()\n    ↓break")
            : embedInSwitch("something()"),
            embedInSwitch("something()\n    ↓break " + lineComment)
            : embedInSwitch("something()\n     " + lineComment),
            embedInSwitch("something()\n    ↓break\n" + blockComment)
            : embedInSwitch("something()\n" + blockComment),
            embedInSwitch("something()\n    ↓break " + docLineComment)
            : embedInSwitch("something()\n     " + docLineComment),
            embedInSwitch("something()\n    ↓break\n" + docBlockComment)
            : embedInSwitch("something()\n" + docBlockComment),
            embedInSwitch("something()\n    ↓break", case: "default")
            : embedInSwitch("something()", case: "default"),
            embedInSwitch("something()\n    ↓break", case: "case .foo, .foo2 where condition")
            : embedInSwitch("something()", case: "case .foo, .foo2 where condition")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        UnneededBreakInSwitchRuleVisitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintCore.SwiftLintFile) -> SwiftLintCore.ViolationsSyntaxRewriter? {
        UnneededBreakInSwitchRewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
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

private final class UnneededBreakInSwitchRewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [SwiftSyntax.AbsolutePosition] = []
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        guard node.statements.count > 1,
              let statement = node.statements.last,
              let breakStatement = statement.item.as(BreakStmtSyntax.self),
              breakStatement.label == nil,
              !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
            return super.visit(node)
        }

        correctionPositions.append(statement.item.positionAfterSkippingLeadingTrivia)

        let trivia = statement.item.leadingTrivia + statement.item.trailingTrivia

        let stmts = node.statements.removingLast()
        guard let secondLast = stmts.last else { return super.visit(node) }

        let newNode = node
            .with(\.statements, stmts)
            .with(\.statements.trailingTrivia, secondLast.item.trailingTrivia + trivia)
            .trimmed { !$0.isComment }
            .formatted()
            .as(SwitchCaseSyntax.self)!

        return super.visit(newNode)
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

private let lineComment = "// line comment"

private let blockComment = """
/*
    block comment
*/
"""

private let docLineComment = "/// doc line comment"

private let docBlockComment = """
///
/// doc block comment
///
"""
