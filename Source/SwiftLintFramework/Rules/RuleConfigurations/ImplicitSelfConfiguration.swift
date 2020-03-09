public struct ImplicitSelfConfiguration: RuleConfiguration, Equatable {
    public enum InitSelfUsage: String {
        case always = "always"
        case beforeInitCall = "before_init_call"
        case never = "never"
    }

    public var consoleDescription: String {
        return "(severity) \(severity.consoleDescription), " +
            "initSelfUsage: \(initSelfUsage.rawValue)"
    }

    public private(set) var initSelfUsage: InitSelfUsage
    public private(set) var severity: SeverityConfiguration

    public init(severity: ViolationSeverity, initSelfUsage: InitSelfUsage = .never) {
        self.severity = SeverityConfiguration(severity)
        self.initSelfUsage = initSelfUsage
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityConfiguration = configurationDict["severity"] {
            try severity.apply(configuration: severityConfiguration)
        }

        if let initSelfUsageString = configurationDict["initSelfUsage"] as? String,
            let initSelfUsage = InitSelfUsage(rawValue: initSelfUsageString) {
            self.initSelfUsage = initSelfUsage
        }
    }
}
