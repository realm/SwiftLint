@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class CompilerProtocolInitRuleTests: SwiftLintTestCase {
    private let ruleID = CompilerProtocolInitRule.identifier

    func testViolationMessageForExpressibleByIntegerLiteral() throws {
        let config = try XCTUnwrap(makeConfig(nil, ruleID))
        let allViolations = violations(Example("let a = NSNumber(integerLiteral: 1)"), config: config)

        let compilerProtocolInitViolation = allViolations.first { $0.ruleIdentifier == ruleID }
        let violation = try XCTUnwrap(
            compilerProtocolInitViolation,
            "A compiler protocol init violation should have been triggered!"
        )
        XCTAssertEqual(
            violation.reason,
            "Initializers declared in compiler protocol ExpressibleByIntegerLiteral shouldn't be called directly"
        )
    }
}
