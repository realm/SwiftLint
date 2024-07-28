@testable import SwiftLintBuiltInRules
import XCTest

final class TypesafeArrayInitRuleTests: SwiftLintTestCase {
    func testViolationType() {
        let baseDescription = TypesafeArrayInitRule.description
        guard let triggeringExample = baseDescription.triggeringExamples.first else {
            XCTFail("No triggering examples")
            return
        }
        guard let config = makeConfig(nil, baseDescription.identifier) else {
            XCTFail("Could not make configuration")
            return
        }
        let violations = SwiftLintFrameworkTests.violations(triggeringExample, config: config, requiresFileOnDisk: true)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.ruleIdentifier, baseDescription.identifier)
    }
}
