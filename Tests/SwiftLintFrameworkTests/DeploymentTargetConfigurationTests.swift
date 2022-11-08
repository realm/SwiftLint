@testable import SwiftLintFramework
import XCTest

class DeploymentTargetConfigurationTests: SwiftLintTestCase {
    private typealias Version = DeploymentTargetConfiguration.Version

    // swiftlint:disable:next function_body_length
    func testAppliesConfigurationFromDictionary() throws {
        var configuration = DeploymentTargetConfiguration()

        try configuration.apply(configuration: ["iOS_deployment_target": "10.1", "severity": "error"])
        XCTAssertEqual(
            configuration.iOSDeploymentTarget,
            Version(platform: .iOS, major: 10, minor: 1)
        )
        XCTAssertEqual(
            configuration.iOSAppExtensionDeploymentTarget,
            Version(platform: .iOSApplicationExtension, major: 10, minor: 1)
        )
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)

        try configuration.apply(configuration: ["iOSApplicationExtension_deployment_target": "13.0"])
        XCTAssertEqual(
            configuration.iOSDeploymentTarget,
            Version(platform: .iOS, major: 10, minor: 1)
        )
        XCTAssertEqual(
            configuration.iOSAppExtensionDeploymentTarget,
            Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)

        try configuration.apply(configuration: ["macOS_deployment_target": "10.11.3"])
        XCTAssertEqual(
            configuration.iOSDeploymentTarget,
            Version(platform: .iOS, major: 10, minor: 1)
        )
        XCTAssertEqual(
            configuration.iOSAppExtensionDeploymentTarget,
            Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        XCTAssertEqual(
            configuration.macOSDeploymentTarget,
            Version(platform: .macOS, major: 10, minor: 11, patch: 3)
        )
        XCTAssertEqual(
            configuration.macOSAppExtensionDeploymentTarget,
            Version(platform: .macOSApplicationExtension, major: 10, minor: 11, patch: 3)
        )
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)

        try configuration.apply(configuration: ["macOSApplicationExtension_deployment_target": "12.4"])
        XCTAssertEqual(
            configuration.iOSDeploymentTarget,
            Version(platform: .iOS, major: 10, minor: 1)
        )
        XCTAssertEqual(
            configuration.iOSAppExtensionDeploymentTarget,
            Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        XCTAssertEqual(
            configuration.macOSDeploymentTarget,
            Version(platform: .macOS, major: 10, minor: 11, patch: 3)
        )
        XCTAssertEqual(
            configuration.macOSAppExtensionDeploymentTarget,
            Version(platform: .macOSApplicationExtension, major: 12, minor: 4)
        )
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)

        try configuration.apply(configuration: ["severity": "warning"])
        XCTAssertEqual(
            configuration.iOSDeploymentTarget,
            Version(platform: .iOS, major: 10, minor: 1)
        )
        XCTAssertEqual(
            configuration.iOSAppExtensionDeploymentTarget,
            Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        XCTAssertEqual(
            configuration.macOSDeploymentTarget,
            Version(platform: .macOS, major: 10, minor: 11, patch: 3)
        )
        XCTAssertEqual(
            configuration.macOSAppExtensionDeploymentTarget,
            Version(platform: .macOSApplicationExtension, major: 12, minor: 4)
        )
        XCTAssertEqual(configuration.severityConfiguration.severity, .warning)

        try configuration.apply(configuration: ["tvOS_deployment_target": 10.2,
                                                "tvOSApplicationExtension_deployment_target": 9.1,
                                                "watchOS_deployment_target": 5,
                                                "watchOSApplicationExtension_deployment_target": 2.2])
        XCTAssertEqual(
            configuration.iOSDeploymentTarget,
            Version(platform: .iOS, major: 10, minor: 1)
        )
        XCTAssertEqual(
            configuration.iOSAppExtensionDeploymentTarget,
            Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        XCTAssertEqual(
            configuration.macOSDeploymentTarget,
            Version(platform: .macOS, major: 10, minor: 11, patch: 3)
        )
        XCTAssertEqual(
            configuration.macOSAppExtensionDeploymentTarget,
            Version(platform: .macOSApplicationExtension, major: 12, minor: 4)
        )
        XCTAssertEqual(
            configuration.tvOSDeploymentTarget,
            Version(platform: .tvOS, major: 10, minor: 2)
        )
        XCTAssertEqual(
            configuration.tvOSAppExtensionDeploymentTarget,
            Version(platform: .tvOSApplicationExtension, major: 9, minor: 1)
        )
        XCTAssertEqual(
            configuration.watchOSDeploymentTarget,
            Version(platform: .watchOS, major: 5)
        )
        XCTAssertEqual(
            configuration.watchOSAppExtensionDeploymentTarget,
            Version(platform: .watchOSApplicationExtension, major: 2, minor: 2)
        )
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
