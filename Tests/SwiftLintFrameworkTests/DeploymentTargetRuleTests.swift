import SwiftLintFramework
import XCTest

class DeploymentTargetRuleTests: XCTestCase {
    func testRule() {
        verifyRule(DeploymentTargetRule.description)
    }

    // MARK: - Reasons

    func testMacOSAttributeReason() {
        let string = "@availability(macOS 10.11, *)\nclass A {}"
        let violations = self.violations(string, config: ["macOS_deployment_target": "10.14.0"])

        let expectedMessage = "Availability attribute is using a version (10.11) that is satisfied by " +
                              "the deployment target (10.14) for platform macOS."
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, expectedMessage)
    }

    func testWatchOSConditionReason() {
        let string = "if #available(watchOS 4, *) {}"
        let violations = self.violations(string, config: ["watchOS_deployment_target": "5.0.1"])

        let expectedMessage = "Availability condition is using a version (4) that is satisfied by " +
                              "the deployment target (5.0.1) for platform watchOS."
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, expectedMessage)
    }

    private func violations(_ string: String, config: Any?) -> [StyleViolation] {
        guard let config = makeConfig(config, DeploymentTargetRule.description.identifier) else {
            return []
        }

        return SwiftLintFrameworkTests.violations(string, config: config)
    }
}
