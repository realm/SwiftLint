import SwiftSyntax

private func wrapInSwitch(_ str: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    switch foo {
        \(str)
    }
    """, file: file, line: line)
}

struct SwitchCaseOnNewlineRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "switch_case_on_newline",
        name: "Cases on Newline",
        description: "Cases inside a switch should always be on a newline",
        kind: .style,
        nonTriggeringExamples: [
            Example("/*case 1: */return true"),
            Example("//case 1:\n return true"),
            Example("let x = [caseKey: value]"),
            Example("let x = [key: .default]"),
            Example("if case let .someEnum(value) = aFunction([key: 2]) { }"),
            Example("guard case let .someEnum(value) = aFunction([key: 2]) { }"),
            Example("for case let .someEnum(value) = aFunction([key: 2]) { }"),
            Example("enum Environment {\n case development\n}"),
            Example("enum Environment {\n case development(url: URL)\n}"),
            Example("enum Environment {\n case development(url: URL) // staging\n}"),

            wrapInSwitch("case 1:\n return true"),
            wrapInSwitch("default:\n return true"),
            wrapInSwitch("case let value:\n return true"),
            wrapInSwitch("case .myCase: // error from network\n return true"),
            wrapInSwitch("case let .myCase(value) where value > 10:\n return false"),
            wrapInSwitch("case let .myCase(value)\n where value > 10:\n return false"),
            wrapInSwitch("""
            case let .myCase(code: lhsErrorCode, description: _)
             where lhsErrorCode > 10:
            return false
            """),
            wrapInSwitch("case #selector(aFunction(_:)):\n return false\n"),
            Example("""
            do {
              let loadedToken = try tokenManager.decodeToken(from: response)
              return loadedToken
            } catch { throw error }
            """)
        ],
        triggeringExamples: [
            wrapInSwitch("↓case 1: return true"),
            wrapInSwitch("↓case let value: return true"),
            wrapInSwitch("↓default: return true"),
            wrapInSwitch("↓case \"a string\": return false"),
            wrapInSwitch("↓case .myCase: return false // error from network"),
            wrapInSwitch("↓case let .myCase(value) where value > 10: return false"),
            wrapInSwitch("↓case #selector(aFunction(_:)): return false\n"),
            wrapInSwitch("↓case let .myCase(value)\n where value > 10: return false"),
            wrapInSwitch("↓case .first,\n .second: return false")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(locationConverter: file.locationConverter)
    }
}

private extension SwitchCaseOnNewlineRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let locationConverter: SourceLocationConverter

        init(locationConverter: SourceLocationConverter) {
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: SwitchCaseSyntax) {
            guard let caseEndLine = locationConverter.location(for: node.label.endPositionBeforeTrailingTrivia).line,
                  case let statementsPosition = node.statements.positionAfterSkippingLeadingTrivia,
                  let statementStartLine = locationConverter.location(for: statementsPosition).line,
                  statementStartLine == caseEndLine else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
