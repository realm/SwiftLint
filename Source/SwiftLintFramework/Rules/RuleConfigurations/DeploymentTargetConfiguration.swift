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
    private(set) var iOSAppExtensionDeploymentTarget = Version(major: 7)
    private(set) var macOSDeploymentTarget = Version(major: 10, minor: 9)
    private(set) var macOSAppExtensionDeploymentTarget = Version(major: 10, minor: 9)
    private(set) var watchOSDeploymentTarget = Version(major: 1)
    private(set) var watchOSAppExtensionDeploymentTarget = Version(major: 1)
    private(set) var tvOSDeploymentTarget = Version(major: 9)
    private(set) var tvOSAppExtensionDeploymentTarget = Version(major: 9)

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", iOS_deployment_target: \(iOSDeploymentTarget.stringValue)" +
            ", iOSApplicationExtension_deployment_target: \(iOSAppExtensionDeploymentTarget.stringValue)" +
            ", macOS_deployment_target: \(macOSDeploymentTarget.stringValue)" +
            ", macOSApplicationExtension_deployment_target: \(macOSAppExtensionDeploymentTarget.stringValue)" +
            ", watchOS_deployment_target: \(watchOSDeploymentTarget.stringValue)" +
            ", watchOSApplicationExtension_deployment_target: \(watchOSAppExtensionDeploymentTarget.stringValue)" +
            ", tvOS_deployment_target: \(tvOSDeploymentTarget.stringValue)" +
            ", tvOSApplicationExtension_deployment_target: \(tvOSAppExtensionDeploymentTarget.stringValue)"
    }

    public init() {}

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        for (key, value) in configuration {
          try self.appyConfiguration(configuration, for: key, value: value)
        }
    }

  private mutating func appyConfiguration(_ configuration: [String: Any], for key: String, value: Any) throws {
      switch (key, value) {
      case ("severity", let severityString as String):
          try severityConfiguration.apply(configuration: severityString)
      case ("iOS_deployment_target", let deploymentTarget),
        ("iOSApplicationExtension_deployment_target", let deploymentTarget):
          try applyPlatformConfigurationForIOS(configuration, for: key, deploymentTarget: deploymentTarget)
      case ("macOS_deployment_target", let deploymentTarget),
        ("macOSApplicationExtension_deployment_target", let deploymentTarget):
        try applyPlatformConfigurationForMacOS(configuration, for: key, deploymentTarget: deploymentTarget)
      case ("watchOS_deployment_target", let deploymentTarget),
        ("watchOSApplicationExtension_deployment_target", let deploymentTarget):
        try applyPlatformConfigurationForWatchOS(configuration, for: key, deploymentTarget: deploymentTarget)
      case ("tvOS_deployment_target", let deploymentTarget),
        ("tvOSApplicationExtension_deployment_target", let deploymentTarget):
        try applyPlatformConfigurationForTvOS(configuration, for: key, deploymentTarget: deploymentTarget)
      default:
          throw ConfigurationError.unknownConfiguration
      }
    }

    private mutating func applyPlatformConfigurationForIOS(_ configuration: [String: Any],
                                                           for key: String,
                                                           deploymentTarget: Any) throws {
      if key == "iOS_deployment_target" {
        self.iOSDeploymentTarget = try Version(value: deploymentTarget)
        if configuration["iOSApplicationExtension_deployment_target"] == nil {
          self.iOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
        }
      } else if key == "iOSApplicationExtension_deployment_target"{
        self.iOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
      }
    }

    private mutating func applyPlatformConfigurationForMacOS(_ configuration: [String: Any],
                                                             for key: String,
                                                             deploymentTarget: Any) throws {
      if key == "macOS_deployment_target" {
        self.macOSDeploymentTarget = try Version(value: deploymentTarget)
        if configuration["macOSApplicationExtension_deployment_target"] == nil {
          self.macOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
        }
      } else if key == "macOSApplicationExtension_deployment_target"{
        self.macOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
      }
    }

    private mutating func applyPlatformConfigurationForWatchOS(_ configuration: [String: Any],
                                                               for key: String,
                                                               deploymentTarget: Any) throws {
      if key == "watchOS_deployment_target" {
        self.watchOSDeploymentTarget = try Version(value: deploymentTarget)
        if configuration["watchOSApplicationExtension_deployment_target"] == nil {
          self.watchOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
        }
      } else if key == "watchOSApplicationExtension_deployment_target"{
        self.watchOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
      }
    }

    private mutating func applyPlatformConfigurationForTvOS(_ configuration: [String: Any],
                                                            for key: String,
                                                            deploymentTarget: Any) throws {
      if key == "tvOS_deployment_target" {
        self.tvOSDeploymentTarget = try Version(value: deploymentTarget)
        if configuration["tvOSApplicationExtension_deployment_target"] == nil {
          self.tvOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
        }
      } else if key == "tvOSApplicationExtension_deployment_target"{
        self.tvOSAppExtensionDeploymentTarget = try Version(value: deploymentTarget)
      }
    }
}
