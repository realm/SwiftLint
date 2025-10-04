import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct TypesafeArrayInitRuleTests {
    @Test
    func violationRuleIdentifier() throws {
        let baseDescription = TypesafeArrayInitRule.description
        let triggeringExample = try #require(baseDescription.triggeringExamples.first)
        let config = try #require(makeConfig(nil, baseDescription.identifier))
        let violations = violations(triggeringExample, config: config, requiresFileOnDisk: true)
        #expect(violations.first?.ruleIdentifier == baseDescription.identifier)
    }
}
