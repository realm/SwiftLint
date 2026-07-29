import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ClosureEndIndentationRuleTests {
    @Test
    func crlfLineEndings() {
        let correctlyIndented = [
            "struct TestView: View {",
            "    var body: some View {",
            "        HStack {",
            "            VStack {",
            "                Text(\"Hello\")",
            "                Spacer()",
            "            }",
            "        }",
            "    }",
            "}",
            "",
        ].joined(separator: "\r\n")
        let misindented = [
            "struct S {",
            "    func f() {",
            "        run {",
            "            print(\"hi\")",
            "            ↓}",
            "    }",
            "}",
            "",
        ].joined(separator: "\r\n")
        let corrected = [
            "struct S {",
            "    func f() {",
            "        run {",
            "            print(\"hi\")",
            "        }",
            "    }",
            "}",
            "",
        ].joined(separator: "\r\n")

        // testWrappingInString is disabled because the test helper's string
        // wrapping escapes only "\n", leaving bare "\r" bytes in the literal.
        let description = ClosureEndIndentationRule.description
            .with(nonTriggeringExamples: [Example(code: correctlyIndented)])
            .with(triggeringExamples: [Example(code: misindented, testWrappingInString: false)])
            .with(corrections: [Example(code: misindented): Example(code: corrected)])

        verifyRule(description)
    }
}
