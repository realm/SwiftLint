import SwiftLintCore

internal struct NumberSeparatorRuleExamples {
    static let nonTriggeringExamples: [Example] = {
        ["-", "+", ""].flatMap { (sign: String) -> [Example] in
            #examples([
                "let foo = \(sign)100",
                "let foo = \(sign)1_000",
                "let foo = \(sign)1_000_000",
                "let foo = \(sign)1.0001",
                "let foo = \(sign)1_000_000.0000001",
                "let binary = \(sign)0b10000",
                "let binary = \(sign)0b1000_0001",
                "let hex = \(sign)0xA",
                "let hex = \(sign)0xAA_BB",
                "let octal = \(sign)0o21",
                "let octal = \(sign)0o21_1",
                "let exp = \(sign)1_000_000.000000e2",
                "let foo: Double = \(sign)(200)",
                "let foo: Double = \(sign)(200 / 447.214)",
                "let foo = \(sign)6.2832e-6",
                """
                let color = #colorLiteral(red: 0.3543982506, green: 0.318749547, blue: 0.6367015243, alpha: 1)
                """.asExample(excludeFromDocumentation: true),
                """
                let color = #colorLiteral(red: 0.354_398_250_6, green: 0.318_749_547, blue: 0.636_701_524_3, alpha: 1)
                """.asExample(configuration: ["minimum_fraction_length": 3], excludeFromDocumentation: true),
            ])
        }
    }()

    static let triggeringExamples = makeTriggeringExamples(signs: ["-↓", "+↓", "↓"]) +
        makeTriggeringExamplesWithParentheses()

    static let corrections = makeCorrections(signs: [("-↓", "-"), ("+↓", "+"), ("↓", "")])

    private static func makeTriggeringExamples(signs: [String]) -> [Example] {
        signs.flatMap { (sign: String) -> [Example] in
            #examples([
                "let foo = \(sign)10_0",
                "let foo = \(sign)1000",
                "let foo = \(sign)1000e2",
                "let foo = \(sign)1000E2",
                "let foo = \(sign)1__000",
                "let foo = \(sign)1.0001".asExample(configuration: ["minimum_fraction_length": 3]),
                "let foo = \(sign)1_000_000.000000_1".asExample(configuration: ["minimum_fraction_length": 3]),
                "let foo = \(sign)1000000.000000_1",
                "let foo = \(sign)6.2832e-6".asExample(configuration: ["minimum_fraction_length": 3]),
            ])
        }
    }

    private static func makeTriggeringExamplesWithParentheses() -> [Example] {
        let signsWithParenthesisAndViolation = ["-(↓", "+(↓", "(↓"]
        return signsWithParenthesisAndViolation.flatMap { (sign: String) -> [Example] in
            #examples([
                "let foo: Double = \(sign)100000)",
                "let foo: Double = \(sign)10.000000_1)".asExample(configuration: ["minimum_fraction_length": 3]),
                "let foo: Double = \(sign)123456 / ↓447.214214)"
                    .asExample(configuration: ["minimum_fraction_length": 3]),
            ])
        }
    }

    private static func makeCorrections(signs: [(String, String)]) -> [Example: Example] {
        var result = [Example: Example]()

        for (violation, sign) in signs {
            let newExamples = #corrections([
                "let foo = \(violation)10_0": "let foo = \(sign)100",
                "let foo = \(violation)1000": "let foo = \(sign)1_000",
                "let foo = \(violation)1000e2": "let foo = \(sign)1_000e2",
                "let foo = \(violation)1000E2": "let foo = \(sign)1_000E2",
                "let foo = \(violation)1__000": "let foo = \(sign)1_000",
                "let foo = \(violation)1.0001".asExample(configuration: ["minimum_fraction_length": 3]):
                    "let foo = \(sign)1.000_1",
                "let foo = \(violation)1_000_000.000000_1"
                    .asExample(configuration: ["minimum_fraction_length": 3]):
                    "let foo = \(sign)1_000_000.000_000_1",
                "let foo = \(violation)1000000.000000_1".asExample(configuration: ["minimum_fraction_length": 3]):
                    "let foo = \(sign)1_000_000.000_000_1",
                "let foo = \(sign)6.2832e-6".asExample(configuration: ["minimum_fraction_length": 3]):
                    "let foo = \(sign)6.283_2e-6",
            ])
            result.merge(newExamples) {
                queuedFatalError("All keys should be unique, but found duplicate keys for \($0) and \($1)")
            }
        }

        return result
    }
}
