@testable import SwiftLintBuiltInRules
import TestHelpers

final class UnneededOverrideRuleTests: SwiftLintTestCase {
    func testIncludeAffectInits() {
        let nonTriggeringExamples = [
            Example("""
            override init() {
                super.init(frame: .zero)
            }
            """),
            Example("""
            override init?() {
                super.init()
            }
            """),
            Example("""
            override init!() {
                super.init()
            }
            """),
            Example("""
            private override init() {
                super.init()
            }
            """),
        ] + UnneededOverrideRuleExamples.nonTriggeringExamples

        let triggeringExamples = [
            Example("""
            class Foo {
                ↓override init() {
                    super.init()
                }
            }
            """),
            Example("""
            class Foo {
                ↓public override init(frame: CGRect) {
                    super.init(frame: frame)
                }
            }
            """),
        ]

        let corrections = [
            Example("""
            class Foo {
                ↓override init(frame: CGRect) {
                    super.init(frame: frame)
                }
            }
            """): Example("""
                          class Foo {
                          }
                          """),
        ]

        let description = UnneededOverrideRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["affect_initializers": true])
    }
}
