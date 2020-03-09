@testable import SwiftLintFramework
import XCTest

class ImplicitSelfRuleTests: XCTestCase {
    func testInitSelfUsageNever() {
        let nonTriggeringExamples = ImplicitSelfRuleExamples.nonTriggeringExamples + [
            Example("""
            class B { }
            class A: B {
                let p1: Int
                let p2: Int
                init(p1: Int) {
                    self.p1 = p1
                    p2 = 2
                    super.init()
                    _ = self.p1
                    _ = p2
                }
            }
            """)
        ]

        let triggeringExamples = ImplicitSelfRuleExamples.triggeringExamples + [
            Example("""
            class B { }
            class A: B {
                let p1: Int
                let p2: Int
                init(p1: Int) {
                    self.p1 = p1
                    ↓self.p2 = 2
                    super.init()
                    _ = self.p1
                    _ = ↓self.p2
                }
            }
            """)
        ]

        let description = ImplicitSelfRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["initSelfUsage": "never"])
    }

    func testInitSelfUsageAlways() {
        let nonTriggeringExamples = ImplicitSelfRuleExamples.nonTriggeringExamples + [
            Example("""
            class B { }
            class A: B {
                let p1: Int
                let p2: Int
                init(p1: Int) {
                    self.p1 = p1
                    super.init()
                    _ = self.p1
                    _ = self.p2
                }
            }
            """)
        ]

        let triggeringExamples = ImplicitSelfRuleExamples.triggeringExamples

        let description = ImplicitSelfRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["initSelfUsage": "always"])
    }

    func testInitSelfUsageBeforeInitCall() {
        let nonTriggeringExamples = ImplicitSelfRuleExamples.nonTriggeringExamples + [
            Example("""
            class B { }
            class A: B {
                let p1: Int
                let p2: Int
                init(p1: Int) {
                    self.p1 = p1
                    if p1 == 1 {
                        self.p2 = 2
                    } else {
                        self.p2 = 0
                    }
                    super.init()
                    _ = self.p1
                    _ = p2
                }
            }
            """)
        ]

        let triggeringExamples = ImplicitSelfRuleExamples.triggeringExamples + [
            Example("""
            class B { }
            class A: B {
                let p1: Int
                let p2: Int
                init(p1: Int) {
                    self.p1 = p1
                    self.p2 = 2
                    super.init()
                    _ = self.p1
                    _ = ↓self.p2
                }
            }
            """)
        ]

        let description = ImplicitSelfRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["initSelfUsage": "before_init_call"])
    }
}
