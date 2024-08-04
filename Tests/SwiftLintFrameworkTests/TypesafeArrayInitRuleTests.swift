@testable import SwiftLintBuiltInRules
import XCTest

final class TypesafeArrayInitRuleTests: SwiftLintTestCase {
    func testViolationRuleIdentifier() async {
        let baseDescription = TypesafeArrayInitRule.description
        guard let triggeringExample = baseDescription.triggeringExamples.first else {
            XCTFail("No triggering examples found")
            return
        }
        guard let config = makeConfig(nil, baseDescription.identifier) else {
            XCTFail("Failed to create configuration")
            return
        }
        let violations = await SwiftLintFrameworkTests.violations(
            triggeringExample,
            config: config,
            requiresFileOnDisk: true
        )
        XCTAssertGreaterThanOrEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.ruleIdentifier, baseDescription.identifier)
    }
}
