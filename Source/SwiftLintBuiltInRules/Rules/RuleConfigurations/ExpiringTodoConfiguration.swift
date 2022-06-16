struct ExpiringTodoConfiguration: RuleConfiguration, Equatable {
    typealias Parent = ExpiringTodoRule
    typealias Severity = SeverityConfiguration<Parent>

    struct DelimiterConfiguration: Equatable {
        static let `default`: DelimiterConfiguration = .init(opening: "[", closing: "]")

        fileprivate(set) var opening: String
        fileprivate(set) var closing: String
    }

    var parameterDescription: RuleConfigurationDescription? {
        "approaching_expiry_severity" => .severity(approachingExpirySeverity.severity)
        "expired_severity" => .severity(expiredSeverity.severity)
        "bad_formatting_severity" => .severity(badFormattingSeverity.severity)
        "approaching_expiry_threshold" => .integer(approachingExpiryThreshold)
        "date_format" => .string(dateFormat)
        "date_delimiters" => .nest {
            "opening" => .string(dateDelimiters.opening)
            "closing" => .string(dateDelimiters.closing)
        }
        "date_separator" => .string(dateSeparator)
    }

    private(set) var approachingExpirySeverity: Severity

    private(set) var expiredSeverity: Severity

    private(set) var badFormattingSeverity: Severity

    // swiftlint:disable:next todo
    /// The number of days prior to expiry before the TODO emits a violation
    private(set) var approachingExpiryThreshold: Int
    /// The opening/closing characters used to surround the expiry-date string
    private(set) var dateDelimiters: DelimiterConfiguration
    /// The format which should be used to the expiry-date string into a `Date` object
    private(set) var dateFormat: String
    /// The separator used for regex detection of the expiry-date string
    private(set) var dateSeparator: String

    init(
        approachingExpirySeverity: Severity = .init(.warning),
        expiredSeverity: Severity = .init(.error),
        badFormattingSeverity: Severity = .init(.error),
        approachingExpiryThreshold: Int = 15,
        dateFormat: String = "MM/dd/yyyy",
        dateDelimiters: DelimiterConfiguration = .default,
        dateSeparator: String = "/") {
        self.approachingExpirySeverity = approachingExpirySeverity
        self.expiredSeverity = expiredSeverity
        self.badFormattingSeverity = badFormattingSeverity
        self.approachingExpiryThreshold = approachingExpiryThreshold
        self.dateDelimiters = dateDelimiters
        self.dateFormat = dateFormat
        self.dateSeparator = dateSeparator
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let approachingExpiryConfiguration = configurationDict["approaching_expiry_severity"] {
            try approachingExpirySeverity.apply(configuration: approachingExpiryConfiguration)
        }
        if let expiredConfiguration = configurationDict["expired_severity"] {
            try expiredSeverity.apply(configuration: expiredConfiguration)
        }
        if let badFormattingConfiguration = configurationDict["bad_formatting_severity"] {
            try badFormattingSeverity.apply(configuration: badFormattingConfiguration)
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
}
