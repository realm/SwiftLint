struct DeploymentTargetConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = DeploymentTargetRule

    enum Platform: String {
        case iOS
        case iOSApplicationExtension
        case macOS
        case macOSApplicationExtension
        case watchOS
        case watchOSApplicationExtension
        case tvOS
        case tvOSApplicationExtension
        case OSX

        var configurationKey: String {
            rawValue + "_deployment_target"
        }

        var appExtensionCounterpart: WritableKeyPath<DeploymentTargetConfiguration, Version>? {
            switch self {
            case .iOS: \DeploymentTargetConfiguration.iOSAppExtensionDeploymentTarget
            case .macOS: \DeploymentTargetConfiguration.macOSAppExtensionDeploymentTarget
            case .watchOS: \DeploymentTargetConfiguration.watchOSAppExtensionDeploymentTarget
            case .tvOS: \DeploymentTargetConfiguration.tvOSAppExtensionDeploymentTarget
            default: nil
            }
        }
    }

    struct Version: Equatable, Comparable {
        let platform: Platform
        var major: Int
        var minor: Int
        var patch: Int

        var stringValue: String {
            if patch > 0 {
                return "\(major).\(minor).\(patch)"
            }
            return "\(major).\(minor)"
        }

        init(platform: Platform, major: Int, minor: Int = 0, patch: Int = 0) {
            self.platform = platform
            self.major = major
            self.minor = minor
            self.patch = patch
        }

        init(platform: Platform, value: Any) throws {
            let (major, minor, patch) = try Self.parseVersion(string: String(describing: value))
            self.init(platform: platform, major: major, minor: minor, patch: patch)
        }

        var configurationKey: String {
            platform.configurationKey
        }

        private static func parseVersion(string: String) throws -> (Int, Int, Int) {
            func parseNumber(_ string: String) throws -> Int {
                guard let number = Int(string) else {
                    throw Issue.invalidConfiguration(ruleID: Parent.identifier)
                }
                return number
            }

            let parts = string.components(separatedBy: ".")
            switch parts.count {
            case 0:
                throw Issue.invalidConfiguration(ruleID: Parent.identifier)
            case 1:
                return (try parseNumber(parts[0]), 0, 0)
            case 2:
                return (try parseNumber(parts[0]), try parseNumber(parts[1]), 0)
            default:
                return (try parseNumber(parts[0]), try parseNumber(parts[1]), try parseNumber(parts[2]))
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            if lhs.major != rhs.major {
                return lhs.major < rhs.major
            }
            if lhs.minor != rhs.minor {
                return lhs.minor < rhs.minor
            }
            return lhs.patch < rhs.patch
        }
    }

    private(set) var iOSDeploymentTarget = Version(platform: .iOS, major: 7)
    private(set) var iOSAppExtensionDeploymentTarget = Version(platform: .iOSApplicationExtension, major: 7)
    private(set) var macOSDeploymentTarget = Version(platform: .macOS, major: 10, minor: 9)
    private(set) var macOSAppExtensionDeploymentTarget = Version(platform: .macOSApplicationExtension,
                                                                 major: 10, minor: 9)
    private(set) var watchOSDeploymentTarget = Version(platform: .watchOS, major: 1)
    private(set) var watchOSAppExtensionDeploymentTarget = Version(platform: .watchOSApplicationExtension, major: 1)
    private(set) var tvOSDeploymentTarget = Version(platform: .tvOS, major: 9)
    private(set) var tvOSAppExtensionDeploymentTarget = Version(platform: .tvOSApplicationExtension, major: 9)

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    var parameterDescription: RuleConfigurationDescription? {
        let targets = Dictionary(uniqueKeysWithValues: [
                iOSDeploymentTarget,
                iOSAppExtensionDeploymentTarget,
                macOSDeploymentTarget,
                macOSAppExtensionDeploymentTarget,
                watchOSDeploymentTarget,
                watchOSAppExtensionDeploymentTarget,
                tvOSDeploymentTarget,
                tvOSAppExtensionDeploymentTarget,
        ].map { ($0.platform.configurationKey, $0) })
        severityConfiguration
        for (platform, target) in targets.sorted(by: { $0.key < $1.key }) {
            platform => .symbol(target.stringValue)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }
        for (key, value) in configuration {
            if key == "severity", let value = value as? String {
                try severityConfiguration.apply(configuration: value)
                continue
            }
            switch key {
            case iOSDeploymentTarget.platform.configurationKey:
                try apply(value: value, to: \.iOSDeploymentTarget, from: configuration)
            case iOSAppExtensionDeploymentTarget.platform.configurationKey:
                iOSAppExtensionDeploymentTarget = try Version(platform: .iOSApplicationExtension, value: value)
            case macOSDeploymentTarget.platform.configurationKey:
                try apply(value: value, to: \.macOSDeploymentTarget, from: configuration)
            case macOSAppExtensionDeploymentTarget.platform.configurationKey:
                macOSAppExtensionDeploymentTarget = try Version(platform: .macOSApplicationExtension, value: value)
            case watchOSDeploymentTarget.platform.configurationKey:
                try apply(value: value, to: \.watchOSDeploymentTarget, from: configuration)
            case watchOSAppExtensionDeploymentTarget.platform.configurationKey:
                watchOSAppExtensionDeploymentTarget = try Version(platform: .watchOSApplicationExtension, value: value)
            case tvOSDeploymentTarget.platform.configurationKey:
                try apply(value: value, to: \.tvOSDeploymentTarget, from: configuration)
            case tvOSAppExtensionDeploymentTarget.platform.configurationKey:
                tvOSAppExtensionDeploymentTarget = try Version(platform: .tvOSApplicationExtension, value: value)
            default: throw Issue.invalidConfiguration(ruleID: Parent.identifier)
            }
        }
    }

    private mutating func apply(value: Any,
                                to target: WritableKeyPath<Self, Version>,
                                from configuration: [String: Any]) throws {
        let platform = self[keyPath: target].platform
        self[keyPath: target] = try Version(platform: platform, value: value)
        if let counterpart = platform.appExtensionCounterpart,
           case let counterPlatform = self[keyPath: counterpart].platform,
           configuration[counterPlatform.configurationKey] == nil {
            self[keyPath: counterpart] = try Version(platform: counterPlatform, value: value)
        }
    }
}
