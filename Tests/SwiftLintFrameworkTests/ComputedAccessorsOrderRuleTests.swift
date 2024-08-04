@testable import SwiftLintBuiltInRules
import XCTest

final class ComputedAccessorsOrderRuleTests: SwiftLintTestCase {
    func testSetGetConfiguration() async {
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

        await verifyRule(description, ruleConfiguration: ["order": "set_get"])
    }

    func testGetSetPropertyReason() async {
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

        await AsyncAssertEqual(
            await ruleViolations(example).first?.reason,
            "Computed properties should first declare the getter and then the setter"
        )
    }

    func testGetSetSubscriptReason() async {
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

        await AsyncAssertEqual(
            await ruleViolations(example).first?.reason,
            "Computed subscripts should first declare the getter and then the setter"
        )
    }

    func testSetGetPropertyReason() async {
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

        await AsyncAssertEqual(
            await ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason,
            "Computed properties should first declare the setter and then the getter"
        )
    }

    func testSetGetSubscriptReason() async {
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

        await AsyncAssertEqual(
            await ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason,
            "Computed subscripts should first declare the setter and then the getter"
        )
    }

    private func ruleViolations(_ example: Example, ruleConfiguration: Any? = nil) async -> [StyleViolation] {
        guard let config = makeConfig(ruleConfiguration, ComputedAccessorsOrderRule.description.identifier) else {
            return []
        }

        return await violations(example, config: config)
    }
}
