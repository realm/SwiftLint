import SwiftParser
import SwiftSyntax
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct NumberSeparatorRuleTests {
    @Test
    func numberSeparatorWithMinimumLength() {
        let nonTriggeringExamples = #examples([
            "let foo = 10_000",
            "let foo = 1000",
            "let foo = 1000.0001",
            "let foo = 10_000.0001",
            "let foo = 1000.00001",
        ])
        let triggeringExamples = #examples([
            "let foo = ↓1_000",
            "let foo = ↓1.000_1",
            "let foo = ↓1_000.000_1",
        ])
        let corrections = #examplesDictionary([
            "let foo = ↓1_000": "let foo = 1000",
            "let foo = ↓1.000_1": "let foo = 1.0001",
            "let foo = ↓1_000.000_1": "let foo = 1000.0001",
        ])

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_length": 5])
    }

    @Test
    func numberSeparatorWithMinimumFractionLength() {
        let nonTriggeringExamples = #examples([
            "let foo = 1_000.000_000_1",
            "let foo = 1.000_001",
            "let foo = 100.0001",
            "let foo = 1_000.000_01",
        ])
        let triggeringExamples = #examples([
            "let foo = ↓1000",
            "let foo = ↓1.000_1",
            "let foo = ↓1_000.000_1",
        ])
        let corrections = #examplesDictionary([
            "let foo = ↓1000": "let foo = 1_000",
            "let foo = ↓1.000_1": "let foo = 1.0001",
            "let foo = ↓1_000.000_1": "let foo = 1_000.0001",
        ])

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["minimum_fraction_length": 5])
    }

    @Test
    func numberSeparatorWithExcludeRanges() {
        let nonTriggeringExamples = #examples([
            "let foo = 1950",
            "let foo = 1_950",
            "let foo = 1985",
            "let foo = 1_985",
            "let foo = 2020",
            "let foo = 2_020",
            "let foo = 2.10042",
            "let foo = 2.100_42",
            "let foo = 2.833333",
            "let foo = 2.833_333",
        ])
        let triggeringExamples = #examples([
            "let foo = ↓1000",
            "let foo = ↓2100",
            "let foo = ↓1.920442",
            "let foo = ↓3.343434",
        ])
        let corrections = #examplesDictionary([
            "let foo = ↓1000": "let foo = 1_000",
            "let foo = ↓2100": "let foo = 2_100",
            "let foo = ↓1.920442": "let foo = 1.920_442",
            "let foo = ↓3.343434": "let foo = 3.343_434",
        ])

        let description = NumberSeparatorRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(
            description,
            ruleConfiguration: [
                "exclude_ranges": [
                    ["min": 1900, "max": 2030],
                    ["min": 2.0, "max": 3.0],
                ] as Any,
                "minimum_fraction_length": 3,
            ] as Any
        )
    }

    @Test
    func specificViolationReasons() {
        #expect(violations(in: "1_000").isEmpty)
        #expect(violations(in: "1000") == [NumberSeparatorRule.missingSeparatorsReason])
        #expect(
            violations(in: "1.000000", config: ["minimum_fraction_length": 5])
                == [NumberSeparatorRule.missingSeparatorsReason]
        )
        #expect(violations(in: "10_00") == [NumberSeparatorRule.misplacedSeparatorsReason])
        #expect(violations(in: "1_000_0") == [NumberSeparatorRule.misplacedSeparatorsReason])
        #expect(violations(in: "1000.0_00") == [NumberSeparatorRule.misplacedSeparatorsReason])
        #expect(
            violations(in: "10_00", config: ["minimum_length": 5])
                == [NumberSeparatorRule.misplacedSeparatorsReason]
        )
        #expect(
            violations(in: "1000.0_00", config: ["minimum_fraction_length": 5])
                == [NumberSeparatorRule.misplacedSeparatorsReason]
        )
    }

    private func violations(in code: String, config: Any = [Any]()) -> [String] {
        var rule = NumberSeparatorRule()
        try? rule.configuration.apply(configuration: config)
        let visitor = rule.makeVisitor(file: SwiftLintFile(contents: ""))
        visitor.walk(Parser.parse(source: "let a = " + code))
        return visitor.violations.compactMap(\.reason)
    }
}
