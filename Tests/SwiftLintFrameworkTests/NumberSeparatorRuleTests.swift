@testable import SwiftLintFramework
import SwiftParser
import XCTest

class NumberSeparatorRuleTests: XCTestCase {
    func testNumberSeparatorWithMinimumLength() {
        let nonTriggeringExamples = [
            Example("let foo = 10_000"),
            Example("let foo = 1000"),
            Example("let foo = 1000.0001"),
            Example("let foo = 10_000.0001"),
            Example("let foo = 1000.00001")
        ]
        let triggeringExamples = [
            Example("let foo = ↓1_000"),
            Example("let foo = ↓1.000_1"),
            Example("let foo = ↓1_000.000_1")
        ]
        let corrections = [
            Example("let foo = ↓1_000"): Example("let foo = 1000"),
            Example("let foo = ↓1.000_1"): Example("let foo = 1.0001"),
            Example("let foo = ↓1_000.000_1"): Example("let foo = 1000.0001")
        ]

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_length": 5])
    }

    func testNumberSeparatorWithMinimumFractionLength() {
        let nonTriggeringExamples = [
            Example("let foo = 1_000.000_000_1"),
            Example("let foo = 1.000_001"),
            Example("let foo = 100.0001"),
            Example("let foo = 1_000.000_01")
        ]
        let triggeringExamples = [
            Example("let foo = ↓1000"),
            Example("let foo = ↓1.000_1"),
            Example("let foo = ↓1_000.000_1")
        ]
        let corrections = [
            Example("let foo = ↓1000"): Example("let foo = 1_000"),
            Example("let foo = ↓1.000_1"): Example("let foo = 1.0001"),
            Example("let foo = ↓1_000.000_1"): Example("let foo = 1_000.0001")
        ]

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_fraction_length": 5])
    }

    func testNumberSeparatorWithExcludeRanges() {
        let nonTriggeringExamples = [
            Example("let foo = 1950"),
            Example("let foo = 1_950"),
            Example("let foo = 1985"),
            Example("let foo = 1_985"),
            Example("let foo = 2020"),
            Example("let foo = 2_020"),
            Example("let foo = 2.10042"),
            Example("let foo = 2.100_42"),
            Example("let foo = 2.833333"),
            Example("let foo = 2.833_333")
        ]
        let triggeringExamples = [
            Example("let foo = ↓1000"),
            Example("let foo = ↓2100"),
            Example("let foo = ↓1.920442"),
            Example("let foo = ↓3.343434")
        ]
        let corrections = [
            Example("let foo = ↓1000"): Example("let foo = 1_000"),
            Example("let foo = ↓2100"): Example("let foo = 2_100"),
            Example("let foo = ↓1.920442"): Example("let foo = 1.920_442"),
            Example("let foo = ↓3.343434"): Example("let foo = 3.343_434")
        ]

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(
            description,
            ruleConfiguration: [
                "exclude_ranges": [
                    ["min": 1900, "max": 2030],
                    ["min": 2.0, "max": 3.0]
                ],
                "minimum_fraction_length": 3
            ]
        )
    }

    func testSpecificViolationReasons() {
        XCTAssertEqual(
            violations(in: "1_000"),
            []
        )
        XCTAssertEqual(
            violations(in: "1000"),
            [NumberSeparatorRule.missingSeparatorsReason]
        )
        XCTAssertEqual(
            violations(in: "1.000000", config: ["minimum_fraction_length": 5]),
            [NumberSeparatorRule.missingSeparatorsReason]
        )
        XCTAssertEqual(
            violations(in: "10_00"),
            [NumberSeparatorRule.misplacedSeparatorsReason]
        )
        XCTAssertEqual(
            violations(in: "1_000_0"),
            [NumberSeparatorRule.misplacedSeparatorsReason]
        )
        XCTAssertEqual(
            violations(in: "1000.0_00"),
            [NumberSeparatorRule.misplacedSeparatorsReason]
        )
        XCTAssertEqual(
            violations(in: "10_00", config: ["minimum_length": 5]),
            [NumberSeparatorRule.misplacedSeparatorsReason]
        )
        XCTAssertEqual(
            violations(in: "1000.0_00", config: ["minimum_fraction_length": 5]),
            [NumberSeparatorRule.misplacedSeparatorsReason]
        )
    }

    private func violations(in code: String, config: Any = []) -> [String] {
        var rule = NumberSeparatorRule()
        try? rule.configuration.apply(configuration: config)
        let visitor = rule.makeVisitor(file: SwiftLintFile(contents: ""))
        visitor.walk(Parser.parse(source: "let a = " + code))
        return visitor.violations.compactMap(\.reason)
    }
}
