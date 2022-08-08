@testable import SwiftLintFramework
import XCTest

class ComputedAccessorsOrderRuleTests: XCTestCase {
    func testWithDefaultConfiguration() async {
        // Test with default parameters
        await verifyRule(ComputedAccessorsOrderRule.description)
    }

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
            """)
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
            """)
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

        let reason = await ruleViolations(example).first?.reason
        XCTAssertEqual(
            reason,
            "Computed properties should declare first the getter and then the setter."
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

        let reason = await ruleViolations(example).first?.reason
        XCTAssertEqual(
            reason,
            "Computed subscripts should declare first the getter and then the setter."
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

        let reason = await ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason
        XCTAssertEqual(
            reason,
            "Computed properties should declare first the setter and then the getter."
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

        let reason = await ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason
        XCTAssertEqual(
            reason,
            "Computed subscripts should declare first the setter and then the getter."
        )
    }

    private func ruleViolations(_ example: Example, ruleConfiguration: Any? = nil) async -> [StyleViolation] {
        guard let config = makeConfig(ruleConfiguration, ComputedAccessorsOrderRule.description.identifier) else {
            return []
        }

        return await violations(example, config: config)
    }
}
