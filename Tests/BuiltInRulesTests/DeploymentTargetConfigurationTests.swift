import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct DeploymentTargetConfigurationTests {
    private typealias Version = DeploymentTargetConfiguration.Version

    @Test
    func appliesConfigurationFromDictionary() throws { // swiftlint:disable:this function_body_length
        var configuration = DeploymentTargetConfiguration()

        try configuration.apply(configuration: ["iOS_deployment_target": "10.1", "severity": "error"])
        #expect(configuration.iOSDeploymentTarget == Version(platform: .iOS, major: 10, minor: 1))
        #expect(
            configuration.iOSAppExtensionDeploymentTarget
                == Version(platform: .iOSApplicationExtension, major: 10, minor: 1)
        )
        #expect(configuration.severityConfiguration.severity == .error)

        try configuration.apply(configuration: ["iOSApplicationExtension_deployment_target": "13.0"])
        #expect(configuration.iOSDeploymentTarget == Version(platform: .iOS, major: 10, minor: 1))
        #expect(
            configuration.iOSAppExtensionDeploymentTarget
                == Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        #expect(configuration.severityConfiguration.severity == .error)

        try configuration.apply(configuration: ["macOS_deployment_target": "10.11.3"])
        #expect(configuration.iOSDeploymentTarget == Version(platform: .iOS, major: 10, minor: 1))
        #expect(
            configuration.iOSAppExtensionDeploymentTarget
                == Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        #expect(configuration.macOSDeploymentTarget == Version(platform: .macOS, major: 10, minor: 11, patch: 3))
        #expect(
            configuration.macOSAppExtensionDeploymentTarget
                == Version(platform: .macOSApplicationExtension, major: 10, minor: 11, patch: 3)
        )
        #expect(configuration.severityConfiguration.severity == .error)

        try configuration.apply(configuration: ["macOSApplicationExtension_deployment_target": "12.4"])
        #expect(configuration.iOSDeploymentTarget == Version(platform: .iOS, major: 10, minor: 1))
        #expect(
            configuration.iOSAppExtensionDeploymentTarget
                == Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        #expect(configuration.macOSDeploymentTarget == Version(platform: .macOS, major: 10, minor: 11, patch: 3))
        #expect(
            configuration.macOSAppExtensionDeploymentTarget
                == Version(platform: .macOSApplicationExtension, major: 12, minor: 4)
        )
        #expect(configuration.severityConfiguration.severity == .error)

        try configuration.apply(configuration: ["severity": "warning"])
        #expect(configuration.iOSDeploymentTarget == Version(platform: .iOS, major: 10, minor: 1))
        #expect(
            configuration.iOSAppExtensionDeploymentTarget
                == Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        #expect(configuration.macOSDeploymentTarget == Version(platform: .macOS, major: 10, minor: 11, patch: 3))
        #expect(
            configuration.macOSAppExtensionDeploymentTarget
                == Version(platform: .macOSApplicationExtension, major: 12, minor: 4)
        )
        #expect(configuration.severityConfiguration.severity == .warning)

        try configuration.apply(configuration: [
            "tvOS_deployment_target": 10.2,
            "tvOSApplicationExtension_deployment_target": 9.1,
            "watchOS_deployment_target": 5,
            "watchOSApplicationExtension_deployment_target": 2.2,
        ])
        #expect(configuration.iOSDeploymentTarget == Version(platform: .iOS, major: 10, minor: 1))
        #expect(
            configuration.iOSAppExtensionDeploymentTarget
                == Version(platform: .iOSApplicationExtension, major: 13, minor: 0)
        )
        #expect(configuration.macOSDeploymentTarget == Version(platform: .macOS, major: 10, minor: 11, patch: 3))
        #expect(
            configuration.macOSAppExtensionDeploymentTarget
                == Version(platform: .macOSApplicationExtension, major: 12, minor: 4)
        )
        #expect(configuration.tvOSDeploymentTarget == Version(platform: .tvOS, major: 10, minor: 2))
        #expect(
            configuration.tvOSAppExtensionDeploymentTarget
                == Version(platform: .tvOSApplicationExtension, major: 9, minor: 1)
        )
        #expect(configuration.watchOSDeploymentTarget == Version(platform: .watchOS, major: 5))
        #expect(
            configuration.watchOSAppExtensionDeploymentTarget
                == Version(platform: .watchOSApplicationExtension, major: 2, minor: 2)
        )
        #expect(configuration.severityConfiguration.severity == .warning)
    }

    @Test
    func throwsOnBadConfig() {
        let badConfigs: [[String: Any]] = [
            ["iOS_deployment_target": "foo"],
            ["iOS_deployment_target": ""],
            ["iOS_deployment_target": "5.x"],
            ["iOS_deployment_target": true],
            ["invalid": true],
        ]

        for badConfig in badConfigs {
            var configuration = DeploymentTargetConfiguration()
            checkError(Issue.invalidConfiguration(ruleID: DeploymentTargetRule.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }
}
