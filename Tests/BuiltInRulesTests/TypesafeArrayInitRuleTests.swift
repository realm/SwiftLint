@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class TypesafeArrayInitRuleTests: SwiftLintTestCase {
    func testViolationRuleIdentifier() {
        let baseDescription = TypesafeArrayInitRule.description
        guard let triggeringExample = baseDescription.triggeringExamples.first else {
            XCTFail("No triggering examples found")
            return
        }
        guard let config = makeConfig(nil, baseDescription.identifier) else {
            XCTFail("Failed to create configuration")
            return
        }
        let violations = violations(triggeringExample, config: config, requiresFileOnDisk: true)
        XCTAssertGreaterThanOrEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.ruleIdentifier, baseDescription.identifier)
    }
}
