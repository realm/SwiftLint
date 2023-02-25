@testable import SwiftLintFramework
import XCTest

class ComputedAccessorsOrderRuleTests: XCTestCase {
    func testSetGetConfiguration() async throws {
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

        try await verifyRule(description, ruleConfiguration: ["order": "set_get"])
    }

    func testGetSetPropertyReason() async throws {
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

        let ruleViolations = try await ruleViolations(example)
        XCTAssertEqual(
            ruleViolations.first?.reason,
            "Computed properties should first declare the getter and then the setter"
        )
    }

    func testGetSetSubscriptReason() async throws {
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

        let ruleViolations = try await ruleViolations(example)
        XCTAssertEqual(
            ruleViolations.first?.reason,
            "Computed subscripts should first declare the getter and then the setter"
        )
    }

    func testSetGetPropertyReason() async throws {
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

        let ruleViolations = try await ruleViolations(example, ruleConfiguration: ["order": "set_get"])
        XCTAssertEqual(
            ruleViolations.first?.reason,
            "Computed properties should first declare the setter and then the getter"
        )
    }

    func testSetGetSubscriptReason() async throws {
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

        let ruleViolations = try await ruleViolations(example, ruleConfiguration: ["order": "set_get"])
        XCTAssertEqual(
            ruleViolations.first?.reason,
            "Computed subscripts should first declare the setter and then the getter"
        )
    }

    private func ruleViolations(_ example: Example, ruleConfiguration: Any? = nil) async throws -> [StyleViolation] {
        guard let config = makeConfig(ruleConfiguration, ComputedAccessorsOrderRule.description.identifier) else {
            return []
        }

        return try await violations(example, config: config)
    }
}
