import SwiftSyntax

struct DeploymentTargetRule: ConfigurationProviderRule, SwiftSyntaxRule {
    private typealias Version = DeploymentTargetConfiguration.Version
    var configuration = DeploymentTargetConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "deployment_target",
        name: "Deployment Target",
        description: "Availability checks or attributes shouldn't be using older versions " +
                     "that are satisfied by the deployment target.",
        kind: .lint,
        nonTriggeringExamples: DeploymentTargetRuleExamples.nonTriggeringExamples,
        triggeringExamples: DeploymentTargetRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(platformToConfiguredMinVersion: platformToConfiguredMinVersion)
    }

    private var platformToConfiguredMinVersion: [String: Version] {
        return [
            "iOS": configuration.iOSDeploymentTarget,
            "iOSApplicationExtension": configuration.iOSAppExtensionDeploymentTarget,
            "macOS": configuration.macOSDeploymentTarget,
            "macOSApplicationExtension": configuration.macOSAppExtensionDeploymentTarget,
            "OSX": configuration.macOSDeploymentTarget,
            "tvOS": configuration.tvOSDeploymentTarget,
            "tvOSApplicationExtension": configuration.tvOSAppExtensionDeploymentTarget,
            "watchOS": configuration.watchOSDeploymentTarget,
            "watchOSApplicationExtension": configuration.watchOSAppExtensionDeploymentTarget
        ]
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
}

private extension DeploymentTargetRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        private let platformToConfiguredMinVersion: [String: Version]

        init(platformToConfiguredMinVersion: [String: Version]) {
            self.platformToConfiguredMinVersion = platformToConfiguredMinVersion
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: AttributeSyntax) {
            guard let argument = node.argument?.as(AvailabilitySpecListSyntax.self) else {
                return
            }

            for arg in argument {
                guard let entry = arg.entry.as(AvailabilityVersionRestrictionSyntax.self),
                      let versionString = entry.version?.description,
                      case let platform = entry.platform,
                      let reason = reason(platform: platform, version: versionString, violationType: .attribute) else {
                    continue
                }

                violations.append(
                    ReasonedRuleViolation(
                        position: node.atSignToken.positionAfterSkippingLeadingTrivia,
                        reason: reason
                    )
                )
            }
        }

        override func visitPost(_ node: UnavailabilityConditionSyntax) {
            for elem in node.availabilitySpec {
                guard let restriction = elem.entry.as(AvailabilityVersionRestrictionSyntax.self),
                      let versionString = restriction.version?.description,
                      let reason = reason(platform: restriction.platform, version: versionString,
                                          violationType: .negativeCondition) else {
                    continue
                }

                violations.append(
                    ReasonedRuleViolation(
                        position: node.poundUnavailableKeyword.positionAfterSkippingLeadingTrivia,
                        reason: reason
                    )
                )
            }
        }

        override func visitPost(_ node: AvailabilityConditionSyntax) {
            for elem in node.availabilitySpec {
                guard let restriction = elem.entry.as(AvailabilityVersionRestrictionSyntax.self),
                      let versionString = restriction.version?.description,
                      let reason = reason(platform: restriction.platform, version: versionString,
                                          violationType: .condition) else {
                    continue
                }

                violations.append(
                    ReasonedRuleViolation(
                        position: node.poundAvailableKeyword.positionAfterSkippingLeadingTrivia,
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

            guard let version = try? Version(platform: platform, rawValue: versionString),
                version <= minVersion else {
                    return nil
            }

            return """
            Availability \(violationType.displayString) is using a version (\(versionString)) that is \
            satisfied by the deployment target (\(minVersion.stringValue)) for platform \(platform.rawValue).
            """
        }
    }
}
