import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct UnneededOverrideRuleTests {
    @Test
    func includeAffectInits() {
        let nonTriggeringExamples = #examples([
            """
            override init() {
                super.init(frame: .zero)
            }
            """,
            """
            override init?() {
                super.init()
            }
            """,
            """
            override init!() {
                super.init()
            }
            """,
            """
            private override init() {
                super.init()
            }
            """,
        ]) + UnneededOverrideRuleExamples.nonTriggeringExamples

        let triggeringExamples = #examples([
            """
            class Foo {
                ↓override init() {
                    super.init()
                }
            }
            """,
            """
            class Foo {
                ↓public override init(frame: CGRect) {
                    super.init(frame: frame)
                }
            }
            """,
        ])

        let corrections = #examplesDictionary([
            """
            class Foo {
                ↓override init(frame: CGRect) {
                    super.init(frame: frame)
                }
            }
            """: """
                 class Foo {
                 }
                 """,
        ])

        let description = UnneededOverrideRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["affect_initializers": true])
    }
}
