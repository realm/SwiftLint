import Foundation
import SourceKittenFramework

public struct DeploymentTargetRule: ConfigurationProviderRule {
    private typealias Version = DeploymentTargetConfiguration.Version
    public var configuration = DeploymentTargetConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "deployment_target",
        name: "Deployment Target",
        description: "Availability checks or attributes shouldn't be using older versions " +
                     "that are satisfied by the deployment target.",
        kind: .lint,
        nonTriggeringExamples: DeploymentTargetRuleExamples.nonTriggeringExamples,
        triggeringExamples: DeploymentTargetRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        var violations = validateAttributes(file: file, dictionary: file.structureDictionary)
        violations += validateConditions(file: file, type: .condition)
        violations += validateConditions(file: file, type: .negativeCondition)
        violations.sort(by: { $0.location < $1.location })

        return violations
    }

    private func validateConditions(file: SwiftLintFile, type: AvailabilityType) -> [StyleViolation] {
        guard SwiftVersion.current >= type.requiredSwiftVersion else {
            return []
        }

        let pattern = "#\(type.keyword)\\s*\\([^\\(]+\\)"

        return file.rangesAndTokens(matching: pattern).flatMap { range, tokens -> [StyleViolation] in
            guard let availabilityToken = tokens.first,
                availabilityToken.kind == .keyword,
                let tokenRange = file.stringView.byteRangeToNSRange(availabilityToken.range)
            else {
                return []
            }

            let rangeToSearch = NSRange(location: tokenRange.upperBound, length: range.length - tokenRange.length)
            return validate(range: rangeToSearch, file: file, violationType: type,
                            byteOffsetToReport: availabilityToken.offset)
        }
    }

    private func validateAttributes(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> [StyleViolation] {
        return dictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.declarationKind else { return nil }
            return validateAttributes(file: file, kind: kind, dictionary: subDict)
        }
    }

    private func validateAttributes(file: SwiftLintFile,
                                    kind: SwiftDeclarationKind,
                                    dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let attributes = dictionary.swiftAttributes.filter {
            $0.attribute.flatMap(SwiftDeclarationAttributeKind.init) == .available
        }
        guard attributes.isNotEmpty else {
            return []
        }

        let contents = file.stringView
        return attributes.flatMap { dictionary -> [StyleViolation] in
            guard let byteRange = dictionary.byteRange,
                let range = contents.byteRangeToNSRange(byteRange)
            else {
                return []
            }

            return validate(range: range, file: file, violationType: .attribute,
                            byteOffsetToReport: byteRange.location)
        }.unique
    }

    private func validate(range: NSRange, file: SwiftLintFile, violationType: AvailabilityType,
                          byteOffsetToReport: ByteCount) -> [StyleViolation] {
        let platformToConfiguredMinVersion = self.platformToConfiguredMinVersion
        let allPlatforms = "(?:" + platformToConfiguredMinVersion.keys.joined(separator: "|") + ")"
        let pattern = "\(allPlatforms) [\\d\\.]+"

        return file.rangesAndTokens(matching: pattern, range: range).compactMap { _, tokens -> StyleViolation? in
            guard tokens.count == 2,
                tokens.kinds == [.keyword, .number],
                let platformString = file.contents(for: tokens[0]),
                let platform = DeploymentTargetConfiguration.Platform(rawValue: platformString),
                let minVersion = platformToConfiguredMinVersion[platformString],
                let versionString = file.contents(for: tokens[1]) else {
                    return nil
            }

            guard let version = try? Version(platform: platform, rawValue: versionString),
                version <= minVersion else {
                    return nil
            }

            let reason = """
            Availability \(violationType.displayString) is using a version (\(versionString)) that is \
            satisfied by the deployment target (\(minVersion.stringValue)) for platform \(platformString).
            """
            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: byteOffsetToReport),
                                  reason: reason)
        }
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

        var keyword: String {
            switch self {
            case .condition, .attribute:
                return "available"
            case .negativeCondition:
                return "unavailable"
            }
        }

        var requiredSwiftVersion: SwiftVersion {
            switch self {
            case .condition, .attribute:
                return .five
            case .negativeCondition:
                return .fiveDotSix
            }
        }
    }
}
