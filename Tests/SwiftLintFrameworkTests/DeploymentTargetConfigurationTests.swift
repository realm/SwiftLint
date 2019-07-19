@testable import SwiftLintFramework
import XCTest

class DeploymentTargetConfigurationTests: XCTestCase {
    typealias Version = DeploymentTargetConfiguration.Version

    func testAppliesConfigurationFromDictionary() throws {
        var configuration = DeploymentTargetConfiguration()

        try configuration.apply(configuration: ["iOS_deployment_target": "10.1", "severity": "error"])
        XCTAssertEqual(configuration.iOSDeploymentTarget, Version(major: 10, minor: 1))
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)

        try configuration.apply(configuration: ["macOS_deployment_target": "10.11.3"])
        XCTAssertEqual(configuration.iOSDeploymentTarget, Version(major: 10, minor: 1))
        XCTAssertEqual(configuration.macOSDeploymentTarget, Version(major: 10, minor: 11, patch: 3))
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)

        try configuration.apply(configuration: ["severity": "warning"])
        XCTAssertEqual(configuration.iOSDeploymentTarget, Version(major: 10, minor: 1))
        XCTAssertEqual(configuration.macOSDeploymentTarget, Version(major: 10, minor: 11, patch: 3))
        XCTAssertEqual(configuration.severityConfiguration.severity, .warning)

        try configuration.apply(configuration: ["tvOS_deployment_target": 10.2,
                                                "watchOS_deployment_target": 5])
        XCTAssertEqual(configuration.iOSDeploymentTarget, Version(major: 10, minor: 1))
        XCTAssertEqual(configuration.macOSDeploymentTarget, Version(major: 10, minor: 11, patch: 3))
        XCTAssertEqual(configuration.tvOSDeploymentTarget, Version(major: 10, minor: 2))
        XCTAssertEqual(configuration.watchOSDeploymentTarget, Version(major: 5))
        XCTAssertEqual(configuration.severityConfiguration.severity, .warning)
    }

    func testThrowsOnBadConfig() {
        let badConfigs: [[String: Any]] = [
            ["iOS_deployment_target": "foo"],
            ["iOS_deployment_target": ""],
            ["iOS_deployment_target": "5.x"],
            ["iOS_deployment_target": true],
            ["invalid": true]
        ]

        for badConfig in badConfigs {
            var configuration = DeploymentTargetConfiguration()
            checkError(ConfigurationError.unknownConfiguration) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }
}
