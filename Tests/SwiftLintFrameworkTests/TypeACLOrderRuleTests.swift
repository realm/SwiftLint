@testable import SwiftLintFramework
import XCTest

class TypeACLOrderRuleTests: XCTestCase {
    func testTypeACLOrderRuleWithDefaultConfiguration() {
        verifyRule(TypeACLOrderRule.description)
    }

    func testTypeACLOrderRuleWithCustomOrder() {
        let nonTriggeringExamples: [Example] = [
            Example("""
            class Paddys {
                private let employees = ["Dee"]
                fileprivate let doorLabel = "Pirate"
                static var numCatsInWall = 2
                public let owners = ["Mac", "Dennis", "Charlie"]
                open let location = "Philedelphia"

                internal func drink() { } // Ignore excluded ACL
                private func makeMoney() { }
                open func charlieWork() { }
            }
            """)
        ]

        let triggeringExamples: [Example] = [
            Example("""
            class Paddys {
                public let owners = ["Mac", "Dennis", "Charlie"]
                fileprivate ↓let doorLabel = "Pirate"
                private ↓let employees = ["Dee"]
                open let location = "Philedelphia"

                open func charlieWork() { }
                private ↓func makeMoney() { }
                internal func drink() { } // Ignore excluded ACL
            }
            """)
        ]

        let customOrderDescription = TypeACLOrderRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(
            customOrderDescription,
            ruleConfiguration: [
                "order": [
                    "private",
                    "fileprivate",
                    "Chardee MacDennis", // Ignore non-ACL keywords
                    "public",
                    "open"
                ]
            ]
        )
    }
}
