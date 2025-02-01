import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ComputedAccessorsOrderRuleTests {
    @Test
    func setGetConfiguration() {
        let nonTriggeringExamples = [
            Example("""
            class Foo {
                var foo: Int {
                    set {
                        print(newValue)
                    }
                    get {
                        return 20
                    }
                }
            }
            """),
        ]
        let triggeringExamples = [
            Example("""
            class Foo {
                var foo: Int {
                    ↓get {
                        print(newValue)
                    }
                    set {
                        return 20
                    }
                }
            }
            """),
        ]

        let description = ComputedAccessorsOrderRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["order": "set_get"])
    }

    @Test
    func getSetPropertyReason() {
        let example = Example("""
        class Foo {
            var foo: Int {
                set {
                    return 20
                }
                get {
                    print(newValue)
                }
            }
        }
        """)

        #expect(
            ruleViolations(example).first?.reason
                == "Computed properties should first declare the getter and then the setter"
        )
    }

    @Test
    func getSetSubscriptReason() {
        let example = Example("""
        class Foo {
            subscript(i: Int) -> Int {
                set {
                    print(i)
                }
                get {
                    return 20
                }
            }
        }
        """)

        #expect(
            ruleViolations(example).first?.reason
                == "Computed subscripts should first declare the getter and then the setter"
        )
    }

    @Test
    func setGetPropertyReason() {
        let example = Example("""
        class Foo {
            var foo: Int {
                get {
                    print(newValue)
                }
                set {
                    return 20
                }
            }
        }
        """)

        #expect(
            ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason
                == "Computed properties should first declare the setter and then the getter"
        )
    }

    @Test
    func setGetSubscriptReason() {
        let example = Example("""
        class Foo {
            subscript(i: Int) -> Int {
                get {
                    return 20
                }
                set {
                    print(i)
                }
            }
        }
        """)

        #expect(
            ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason
                == "Computed subscripts should first declare the setter and then the getter"
        )
    }

    private func ruleViolations(_ example: Example, ruleConfiguration: Any? = nil) -> [StyleViolation] {
        guard let config = makeConfig(ruleConfiguration, ComputedAccessorsOrderRule.identifier) else {
            return []
        }
        return violations(example, config: config)
    }
}
