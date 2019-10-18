public struct ExpiringTodoConfiguration: RuleConfiguration, Equatable {
    public struct DelimiterConfiguration: Equatable {
        public static let `default`: DelimiterConfiguration = .init(opening: "[", closing: "]")

        fileprivate(set) var opening: String
        fileprivate(set) var closing: String
    }

    public var consoleDescription: String {
        return "(approaching_expiry_severity) \(approachingExpirySeverity.consoleDescription), " +
        "(reached_or_passed_expiry_severity) \(expiredSeverity.consoleDescription)"
    }

    private(set) var approachingExpirySeverity: SeverityConfiguration

    private(set) var expiredSeverity: SeverityConfiguration

    // swiftlint:disable todo
    /// The number of days prior to expiry before the TODO emits a violation
    // swiftlint:enable todo
    private(set) var approachingExpiryThreshold: Int
    /// The opening/closing characters used to surround the expiry-date string
    private(set) var dateDelimiters: DelimiterConfiguration
    /// The format which should be used to the expiry-date string into a `Date` object
    private(set) var dateFormat: String
    /// The separator used for regex detection of the expiry-date string
    private(set) var dateSeparator: String

    public init(
        approachingExpirySeverity: SeverityConfiguration,
        expiredSeverity: SeverityConfiguration,
        approachingExpiryThreshold: Int = 15,
        dateFormat: String = "MM/dd/yyyy",
        dateDelimiters: DelimiterConfiguration = .default,
        dateSeparator: String = "/") {
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
        if let approachingExpiryThreshold = configurationDict["approaching_expiry_threshold"] as? Int {
            self.approachingExpiryThreshold = approachingExpiryThreshold
        }
        if let dateFormat = configurationDict["date_format"] as? String {
            self.dateFormat = dateFormat
        }
        if let dateDelimiters = configurationDict["date_delimiters"] as? [String: String] {
            if let openingDelimiter = dateDelimiters["opening"] {
                self.dateDelimiters.opening = openingDelimiter
            }
            if let closingDelimiter = dateDelimiters["closing"] {
                self.dateDelimiters.closing = closingDelimiter
            }
        }
        if let dateSeparator = configurationDict["date_separator"] as? String {
            self.dateSeparator = dateSeparator
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
