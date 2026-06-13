import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct CompilerProtocolInitRuleTests {
    private let ruleID = CompilerProtocolInitRule.identifier

    @Test
    func violationMessageForExpressibleByIntegerLiteral() throws {
        let config = try #require(makeConfig(nil, ruleID))
        let allViolations = violations(Example("let a = NSNumber(integerLiteral: 1)"), config: config)
        let violation = try #require(allViolations.first { $0.ruleIdentifier == ruleID })
        #expect(
            violation.reason
                == "Initializers declared in compiler protocol ExpressibleByIntegerLiteral shouldn't be called directly"
        )
    }
}
