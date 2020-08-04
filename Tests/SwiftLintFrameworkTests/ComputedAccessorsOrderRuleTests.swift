@testable import SwiftLintFramework
import XCTest

class ComputedAccessorsOrderRuleTests: XCTestCase {
    func testWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(ComputedAccessorsOrderRule.description)
    }

    func testSetGetConfiguration() {
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

        verifyRule(description, ruleConfiguration: ["order": "set_get"])
    }

    func testGetSetPropertyReason() {
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

        XCTAssertEqual(
            ruleViolations(example).first?.reason,
            "Computed properties should declare first the getter and then the setter."
        )
    }

    func testGetSetSubscriptReason() {
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

        XCTAssertEqual(
            ruleViolations(example).first?.reason,
            "Computed subscripts should declare first the getter and then the setter."
        )
    }

    func testSetGetPropertyReason() {
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

        XCTAssertEqual(
            ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason,
            "Computed properties should declare first the setter and then the getter."
        )
    }

    func testSetGetSubscriptReason() {
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

        XCTAssertEqual(
            ruleViolations(example, ruleConfiguration: ["order": "set_get"]).first?.reason,
            "Computed subscripts should declare first the setter and then the getter."
        )
    }

    private func ruleViolations(_ example: Example, ruleConfiguration: Any? = nil) -> [StyleViolation] {
        guard let config = makeConfig(ruleConfiguration, ComputedAccessorsOrderRule.description.identifier) else {
            return []
        }

        return violations(example, config: config)
    }
}
