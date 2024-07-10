internal struct NumberSeparatorRuleExamples {
    static let nonTriggeringExamples: [Example] = {
        ["-", "+", ""].flatMap { (sign: String) -> [Example] in
            [
                Example("let foo = \(sign)100"),
                Example("let foo = \(sign)1_000"),
                Example("let foo = \(sign)1_000_000"),
                Example("let foo = \(sign)1.0001"),
                Example("let foo = \(sign)1_000_000.0000001"),
                Example("let binary = \(sign)0b10000"),
                Example("let binary = \(sign)0b1000_0001"),
                Example("let hex = \(sign)0xA"),
                Example("let hex = \(sign)0xAA_BB"),
                Example("let octal = \(sign)0o21"),
                Example("let octal = \(sign)0o21_1"),
                Example("let exp = \(sign)1_000_000.000000e2"),
                Example("let foo: Double = \(sign)(200)"),
                Example("let foo: Double = \(sign)(200 / 447.214)"),
                Example("let foo = \(sign)6.2832e-6"),
                Example("""
                let color = #colorLiteral(red: 0.3543982506, green: 0.318749547, blue: 0.6367015243, alpha: 1)
                """, excludeFromDocumentation: true),
                Example("""
                let color = #colorLiteral(red: 0.354_398_250_6, green: 0.318_749_547, blue: 0.636_701_524_3, alpha: 1)
                """, configuration: ["minimum_fraction_length": 3], excludeFromDocumentation: true),
            ]
        }
    }()

    static let triggeringExamples = makeTriggeringExamples(signs: ["-↓", "+↓", "↓"]) +
        makeTriggeringExamplesWithParentheses()

    static let corrections = makeCorrections(signs: [("-↓", "-"), ("+↓", "+"), ("↓", "")])

    private static func makeTriggeringExamples(signs: [String]) -> [Example] {
        signs.flatMap { (sign: String) -> [Example] in
            [
                Example("let foo = \(sign)10_0"),
                Example("let foo = \(sign)1000"),
                Example("let foo = \(sign)1000e2"),
                Example("let foo = \(sign)1000E2"),
                Example("let foo = \(sign)1__000"),
                Example("let foo = \(sign)1.0001", configuration: ["minimum_fraction_length": 3]),
                Example("let foo = \(sign)1_000_000.000000_1", configuration: ["minimum_fraction_length": 3]),
                Example("let foo = \(sign)1000000.000000_1"),
                Example("let foo = \(sign)6.2832e-6", configuration: ["minimum_fraction_length": 3]),
            ]
        }
    }

    private static func makeTriggeringExamplesWithParentheses() -> [Example] {
        let signsWithParenthesisAndViolation = ["-(↓", "+(↓", "(↓"]
        return signsWithParenthesisAndViolation.flatMap { (sign: String) -> [Example] in
            [
                Example("let foo: Double = \(sign)100000)"),
                Example("let foo: Double = \(sign)10.000000_1)", configuration: ["minimum_fraction_length": 3]),
                Example(
                    "let foo: Double = \(sign)123456 / ↓447.214214)",
                    configuration: ["minimum_fraction_length": 3]
                ),
            ]
        }
    }

    private static func makeCorrections(signs: [(String, String)]) -> [Example: Example] {
        var result = [Example: Example]()

        for (violation, sign) in signs {
            result[Example("let foo = \(violation)10_0")] = Example("let foo = \(sign)100")
            result[Example("let foo = \(violation)1000")] = Example("let foo = \(sign)1_000")
            result[Example("let foo = \(violation)1000e2")] = Example("let foo = \(sign)1_000e2")
            result[Example("let foo = \(violation)1000E2")] = Example("let foo = \(sign)1_000E2")
            result[Example("let foo = \(violation)1__000")] = Example("let foo = \(sign)1_000")
            result[Example("let foo = \(violation)1.0001", configuration: ["minimum_fraction_length": 3])] =
                Example("let foo = \(sign)1.000_1")
            result[Example("let foo = \(violation)1_000_000.000000_1", configuration: ["minimum_fraction_length": 3])] =
                Example("let foo = \(sign)1_000_000.000_000_1")
            result[Example("let foo = \(violation)1000000.000000_1", configuration: ["minimum_fraction_length": 3])] =
                Example("let foo = \(sign)1_000_000.000_000_1")
            result[Example("let foo = \(sign)6.2832e-6", configuration: ["minimum_fraction_length": 3])] =
                Example("let foo = \(sign)6.283_2e-6")
        }

        return result
    }
}
