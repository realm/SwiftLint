struct DeploymentTargetConfiguration: SeverityBasedRuleConfiguration, Equatable {
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

        var appExtensionCounterpart: Self? {
            switch self {
            case .iOS: return Self.iOSApplicationExtension
            case .macOS: return Self.macOSApplicationExtension
            case .watchOS: return Self.watchOSApplicationExtension
            case .tvOS: return Self.tvOSApplicationExtension
            default: return nil
            }
        }
    }

    class Version: Equatable, Comparable {
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

        convenience init(platform: Platform, rawValue: String) throws {
            let (major, minor, patch) = try Self.parseVersion(string: rawValue)
            self.init(platform: platform, major: major, minor: minor, patch: patch)
        }

        fileprivate func update(using value: Any) throws {
            let (major, minor, patch) = try Self.parseVersion(string: String(describing: value))
            self.major = major
            self.minor = minor
            self.patch = patch
        }

        private static func parseVersion(string: String) throws -> (Int, Int, Int) {
            func parseNumber(_ string: String) throws -> Int {
                guard let number = Int(string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                return number
            }

            let parts = string.components(separatedBy: ".")
            switch parts.count {
            case 0:
                throw ConfigurationError.unknownConfiguration
            case 1:
                return (try parseNumber(parts[0]), 0, 0)
            case 2:
                return (try parseNumber(parts[0]), try parseNumber(parts[1]), 0)
            default:
                return (try parseNumber(parts[0]), try parseNumber(parts[1]), try parseNumber(parts[2]))
            }
        }

        static func == (lhs: Version, rhs: Version) -> Bool {
            lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
        }

        static func < (lhs: Version, rhs: Version) -> Bool {
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

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    private let targets: [String: Version]

    var consoleDescription: String {
        "severity: \(severityConfiguration.consoleDescription)" + targets
            .sorted { $0.key < $1.key }
            .map { ", \($0): \($1.stringValue)" }.joined()
    }

    init() {
        self.targets = Dictionary(uniqueKeysWithValues: [
                iOSDeploymentTarget,
                iOSAppExtensionDeploymentTarget,
                macOSDeploymentTarget,
                macOSAppExtensionDeploymentTarget,
                watchOSDeploymentTarget,
                watchOSAppExtensionDeploymentTarget,
                tvOSDeploymentTarget,
                tvOSAppExtensionDeploymentTarget
        ].map { ($0.platform.configurationKey, $0) })
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        for (key, value) in configuration {
            if key == "severity", let value = value as? String {
                try severityConfiguration.apply(configuration: value)
                continue
            }
            guard let target = targets[key] else {
                throw ConfigurationError.unknownConfiguration
            }
            try target.update(using: value)
            if let extensionConfigurationKey = target.platform.appExtensionCounterpart?.configurationKey,
               configuration[extensionConfigurationKey] == nil,
               let child = targets[extensionConfigurationKey] {
                try child.update(using: value)
            }
        }
    }
}
