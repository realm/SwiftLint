import SwiftLintFramework
import XCTest

class PrivateOutletRuleTests: XCTestCase {
    func testWithAllowPrivateSet() {
        let baseDescription = PrivateOutletRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("class Foo {\n  @IBOutlet private(set) var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet private(set) var label: UILabel!\n}\n"),
            Example("class Foo {\n  @IBOutlet weak private(set) var label: UILabel?\n}\n"),
            Example("class Foo {\n  @IBOutlet private(set) weak var label: UILabel?\n}\n")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["allow_private_set": true])
    }
}
