import SwiftLintFramework
import XCTest

class NumberSeparatorRuleTests: XCTestCase {
    func testNumberSeparatorWithDefaultConfiguration() {
        verifyRule(NumberSeparatorRule.description)
    }

    func testNumberSeparatorWithMinimumLength() {
        let nonTriggeringExamples = [
            "let foo = 10_000",
            "let foo = 1000",
            "let foo = 1000.0001",
            "let foo = 10_000.0001",
            "let foo = 1000.000_01"
        ]
        let triggeringExamples = [
            "let foo = ↓1_000",
            "let foo = ↓1.000_1",
            "let foo = ↓1_000.000_1"
        ]
        let corrections = [
            "let foo = ↓1_000": "let foo = 1000",
            "let foo = ↓1.000_1": "let foo = 1.0001",
            "let foo = ↓1_000.000_1": "let foo = 1000.0001"
        ]

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_length": 5])
    }

    func testNumberSeparatorWithMinimumFractionLength() {
        let nonTriggeringExamples = [
            "let foo = 1_000.000_000_1",
            "let foo = 1.000_001",
            "let foo = 100.0001",
            "let foo = 1_000.000_01"
        ]
        let triggeringExamples = [
            "let foo = ↓1000",
            "let foo = ↓1.000_1",
            "let foo = ↓1_000.000_1"
        ]
        let corrections = [
            "let foo = ↓1000": "let foo = 1_000",
            "let foo = ↓1.000_1": "let foo = 1.0001",
            "let foo = ↓1_000.000_1": "let foo = 1_000.0001"
        ]

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_fraction_length": 5])
    }

    func testNumberSeparatorWithExcludeRanges() {
        let nonTriggeringExamples = [
            "let foo = 1950",
            "let foo = 1_950",
            "let foo = 1985",
            "let foo = 1_985",
            "let foo = 2020",
            "let foo = 2_020",
            "let foo = 2.10042",
            "let foo = 2.100_42",
            "let foo = 2.833333",
            "let foo = 2.833_333"
        ]
        let triggeringExamples = [
            "let foo = ↓1000",
            "let foo = ↓2100",
            "let foo = ↓1.920442",
            "let foo = ↓3.343434"
        ]
        let corrections = [
            "let foo = ↓1000": "let foo = 1_000",
            "let foo = ↓2100": "let foo = 2_100",
            "let foo = ↓1.920442": "let foo = 1.920_442",
            "let foo = ↓3.343434": "let foo = 3.343_434"
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
                ]
            ]
        )
    }
}
