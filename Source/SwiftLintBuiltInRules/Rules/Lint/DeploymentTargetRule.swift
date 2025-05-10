import SwiftSyntax

@SwiftSyntaxRule
struct DeploymentTargetRule: Rule {
    fileprivate typealias Version = DeploymentTargetConfiguration.Version

    var configuration = DeploymentTargetConfiguration()

    static let description = RuleDescription(
        identifier: "deployment_target",
        name: "Deployment Target",
        description: "Availability checks or attributes shouldn't be using older versions " +
                     "that are satisfied by the deployment target.",
        kind: .lint,
        nonTriggeringExamples: DeploymentTargetRuleExamples.nonTriggeringExamples,
        triggeringExamples: DeploymentTargetRuleExamples.triggeringExamples
    )
}

private enum AvailabilityType {
    case condition
    case attribute
    case negativeCondition

    var displayString: String {
        switch self {
        case .condition:
            return "condition"
        case .attribute:
            return "attribute"
        case .negativeCondition:
            return "negative condition"
        }
    }
}

private extension DeploymentTargetRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var platformToConfiguredMinVersion: [String: Version] {
            [
                "iOS": configuration.iOSDeploymentTarget,
                "iOSApplicationExtension": configuration.iOSAppExtensionDeploymentTarget,
                "macOS": configuration.macOSDeploymentTarget,
                "macOSApplicationExtension": configuration.macOSAppExtensionDeploymentTarget,
                "OSX": configuration.macOSDeploymentTarget,
                "tvOS": configuration.tvOSDeploymentTarget,
                "tvOSApplicationExtension": configuration.tvOSAppExtensionDeploymentTarget,
                "watchOS": configuration.watchOSDeploymentTarget,
                "watchOSApplicationExtension": configuration.watchOSAppExtensionDeploymentTarget,
            ]
        }

        override func visitPost(_ node: AttributeSyntax) {
            guard let argument = node.arguments?.as(AvailabilityArgumentListSyntax.self) else {
                return
            }

            for arg in argument {
                guard let entry = arg.argument.as(PlatformVersionSyntax.self),
                      let versionString = entry.version?.description,
                      case let platform = entry.platform,
                      let reason = reason(platform: platform, version: versionString, violationType: .attribute) else {
                    continue
                }

                violations.append(
                    ReasonedRuleViolation(
                        position: node.atSign.positionAfterSkippingLeadingTrivia,
                        reason: reason
                    )
                )
            }
        }

        override func visitPost(_ node: AvailabilityConditionSyntax) {
            let violationType: AvailabilityType
            switch node.availabilityKeyword.tokenKind {
            case .poundUnavailable:
                violationType = .negativeCondition
            case .poundAvailable:
                violationType = .condition
            default:
                queuedFatalError("Unknown availability check type.")
            }

            for elem in node.availabilityArguments {
                guard let restriction = elem.argument.as(PlatformVersionSyntax.self),
                      let versionString = restriction.version?.description,
                      let reason = reason(platform: restriction.platform, version: versionString,
                                          violationType: violationType) else {
                    continue
                }

                violations.append(
                    ReasonedRuleViolation(
                        position: node.availabilityKeyword.positionAfterSkippingLeadingTrivia,
                        reason: reason
                    )
                )
            }
        }

        private func reason(platform: TokenSyntax,
                            version versionString: String,
                            violationType: AvailabilityType) -> String? {
            guard let platform = DeploymentTargetConfiguration.Platform(rawValue: platform.text),
                  let minVersion = platformToConfiguredMinVersion[platform.rawValue] else {
                    return nil
            }

            guard let version = try? Version(platform: platform, value: versionString),
                version <= minVersion else {
                    return nil
            }

            return """
            Availability \(violationType.displayString) is using a version (\(versionString)) that is \
            satisfied by the deployment target (\(minVersion.stringValue)) for platform \(platform.rawValue)
            """
        }
    }
}
