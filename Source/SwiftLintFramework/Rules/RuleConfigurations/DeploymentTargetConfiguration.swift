public struct DeploymentTargetConfiguration: RuleConfiguration, Equatable {
    public struct Version: Equatable, Comparable {
        public let major: Int
        public let minor: Int
        public let patch: Int

        public var stringValue: String {
            if patch > 0 {
                return "\(major).\(minor).\(patch)"
            } else {
                return "\(major).\(minor)"
            }
        }

        public init(major: Int, minor: Int = 0, patch: Int = 0) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }

        public init(rawValue: String) throws {
            func parseNumber(_ string: String) throws -> Int {
                guard let number = Int(string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                return number
            }

            let parts = rawValue.components(separatedBy: ".")
            let count = parts.count
            switch count {
            case 0:
                throw ConfigurationError.unknownConfiguration
            case 1:
                major = try parseNumber(parts[0])
                minor = 0
                patch = 0
            case 2:
                major = try parseNumber(parts[0])
                minor = try parseNumber(parts[1])
                patch = 0
            default:
                major = try parseNumber(parts[0])
                minor = try parseNumber(parts[1])
                patch = try parseNumber(parts[2])
            }
        }

        fileprivate init(value: Any) throws {
            if let version = value as? String {
                try self.init(rawValue: version)
            } else {
                try self.init(rawValue: String(describing: value))
            }
        }

        public static func < (lhs: Version, rhs: Version) -> Bool {
            if lhs.major != rhs.major {
                return lhs.major < rhs.major
            } else if lhs.minor != rhs.minor {
                return lhs.minor < rhs.minor
            } else {
                return lhs.patch < rhs.patch
            }
        }
    }

    private(set) var iOSDeploymentTarget = Version(major: 7)
    private(set) var macOSDeploymentTarget = Version(major: 10, minor: 9)
    private(set) var watchOSDeploymentTarget = Version(major: 1)
    private(set) var tvOSDeploymentTarget = Version(major: 9)

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", iOS_deployment_target: \(iOSDeploymentTarget.stringValue)" +
            ", macOS_deployment_target: \(macOSDeploymentTarget.stringValue)" +
            ", watchOS_deployment_target: \(watchOSDeploymentTarget.stringValue)" +
            ", tvOS_deployment_target: \(tvOSDeploymentTarget.stringValue)"
    }

    public init() {}

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        for (key, value) in configuration {
            switch (key, value) {
            case ("severity", let severityString as String):
                try severityConfiguration.apply(configuration: severityString)
            case ("iOS_deployment_target", let deploymentTarget):
                self.iOSDeploymentTarget = try Version(value: deploymentTarget)
            case ("macOS_deployment_target", let deploymentTarget):
                self.macOSDeploymentTarget = try Version(value: deploymentTarget)
            case ("watchOS_deployment_target", let deploymentTarget):
                self.watchOSDeploymentTarget = try Version(value: deploymentTarget)
            case ("tvOS_deployment_target", let deploymentTarget):
                self.tvOSDeploymentTarget = try Version(value: deploymentTarget)
            default:
                throw ConfigurationError.unknownConfiguration
            }
        }
    }
}
