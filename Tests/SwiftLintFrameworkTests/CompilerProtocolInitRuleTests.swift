@testable import SwiftLintFramework
import XCTest

class CompilerProtocolInitRuleTests: XCTestCase {
    private let ruleID = CompilerProtocolInitRule.description.identifier

    func testWithDefaultConfiguration() {
        verifyRule(CompilerProtocolInitRule.description)
    }

    func testViolationMessageForExpressibleByIntegerLiteral() {
        guard let config = makeConfig(nil, ruleID) else {
            XCTFail("Failed to create configuration")
            return
        }
        let allViolations = violations("let a = NSNumber(integerLiteral: 1)", config: config)

        let compilerProtocolInitViolation = allViolations.first { $0.ruleDescription.identifier == ruleID }
        if let violation = compilerProtocolInitViolation {
            XCTAssertEqual(
                violation.reason,
                "The initializers declared in compiler protocol ExpressibleByIntegerLiteral " +
                "shouldn't be called directly."
            )
        } else {
            XCTFail("A compiler protocol init violation should have been triggered!")
        }
    }
}
