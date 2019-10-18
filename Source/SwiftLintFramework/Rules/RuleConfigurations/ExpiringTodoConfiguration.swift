public struct ExpiringTodoConfiguration: RuleConfiguration, Equatable {
    public struct DelimiterConfiguration: Equatable {
        public static let `default`: DelimiterConfiguration = .init(opening: "[", closing: "]")

        let opening: Character
        let closing: Character
    }

    public var consoleDescription: String {
        return "(approaching_expiry_severity) \(approachingExpirySeverity.consoleDescription), " +
        "(reached_or_passed_expiry_severity) \(expiredSeverity.consoleDescription)"
    }

    var approachingExpirySeverity: SeverityConfiguration
    var expiredSeverity: SeverityConfiguration

    // swiftlint:disable todo
    /// The number of days prior to expiry before the TODO emits a violation
    // swiftlint:enable todo
    let approachingExpiryThreshold: Int
    /// The opening/closing characters used to surround the expiry-date string
    let dateDelimiters: DelimiterConfiguration
    /// The format which should be used to the expiry-date string into a `Date` object
    let dateFormat: String
    /// The separator used for regex detection of the expiry-date string
    let dateSeparator: Character

    public init(
        approachingExpirySeverity: SeverityConfiguration,
        expiredSeverity: SeverityConfiguration,
        approachingExpiryThreshold: Int = 15,
        dateFormat: String = "mm/DD/yyyy",
        dateDelimiters: DelimiterConfiguration = .default,
        dateSeparator: Character = "/") {
        self.approachingExpirySeverity = approachingExpirySeverity
        self.expiredSeverity = expiredSeverity
        self.approachingExpiryThreshold = approachingExpiryThreshold
        self.dateDelimiters = dateDelimiters
        self.dateFormat = dateFormat
        self.dateSeparator = dateSeparator
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let approachingExpiryConfiguration = configurationDict["approaching_expiry_severity"] {
            try approachingExpirySeverity.apply(configuration: approachingExpiryConfiguration)
        }
        if let expiredConfiguration = configurationDict["expired_severity"] {
            try expiredSeverity.apply(configuration: expiredConfiguration)
        }
    }

    func severity(with config: SeverityLevelsConfiguration, for level: Int) -> ViolationSeverity? {
        if let error = config.error, level > error {
            return .error
        } else if level > config.warning {
            return .warning
        }
        return nil
    }

    func threshold(with config: SeverityLevelsConfiguration, for severity: ViolationSeverity) -> Int {
        switch severity {
        case .error:
            return config.error ?? config.warning
        case .warning:
            return config.warning
        }
    }
}
