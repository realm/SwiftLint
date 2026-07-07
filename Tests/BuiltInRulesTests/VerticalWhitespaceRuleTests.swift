import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct VerticalWhitespaceRuleTests {
    private let ruleID = VerticalWhitespaceRule.identifier

    @Test
    func attributesWithMaxEmptyLines() {
        // Test with custom `max_empty_lines`
        let maxEmptyLinesDescription = VerticalWhitespaceRule.description
            .with(nonTriggeringExamples: [Example("let aaaa = 0\n\n\n")])
            .with(triggeringExamples: [
                Example("struct AAAA {}\n\n\n\n"),
                Example("class BBBB {\n  \n  \n  \n}"),
            ])
            .with(corrections: [:])

        verifyRule(maxEmptyLinesDescription, ruleConfiguration: ["max_empty_lines": 2])
    }

    @Test
    func autoCorrectionWithMaxEmptyLines() {
        let maxEmptyLinesDescription = VerticalWhitespaceRule.description
            .with(nonTriggeringExamples: [])
            .with(triggeringExamples: [])
            .with(corrections: [
                Example("let b = 0\n\n↓\n↓\n↓\n\nclass AAA {}\n"): Example("let b = 0\n\n\nclass AAA {}\n"),
                Example("let b = 0\n\n\nclass AAA {}\n"): Example("let b = 0\n\n\nclass AAA {}\n"),
                Example("class BB {\n  \n  \n↓  \n  let b = 0\n}\n"): Example("class BB {\n  \n  \n  let b = 0\n}\n"),
            ])

        verifyRule(maxEmptyLinesDescription, ruleConfiguration: ["max_empty_lines": 2])
    }

    @Test
    func violationMessageWithMaxEmptyLines() throws {
        let config = try #require(makeConfig(["max_empty_lines": 2], ruleID))
        let allViolations = violations(Example("let aaaa = 0\n\n\n\nlet bbb = 2\n"), config: config)
        let violation = try #require(allViolations.first { $0.ruleIdentifier == ruleID })
        #expect(violation.reason == "Limit vertical whitespace to maximum 2 empty lines; currently 3")
    }

    @Test
    func violationMessageWithDefaultConfiguration() throws {
        let allViolations = violations(Example("let aaaa = 0\n\n\n\nlet bbb = 2\n"))
        let violation = try #require(allViolations.first { $0.ruleIdentifier == ruleID })
        #expect(violation.reason == "Limit vertical whitespace to a single empty line; currently 3")
    }
}
