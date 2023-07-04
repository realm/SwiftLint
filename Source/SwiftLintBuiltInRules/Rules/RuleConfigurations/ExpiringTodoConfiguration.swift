import SwiftLintCore

struct ExpiringTodoConfiguration: RuleConfiguration, Equatable {
    typealias Parent = ExpiringTodoRule
    typealias Severity = SeverityConfiguration<Parent>

    struct DelimiterConfiguration: Equatable, AcceptableByConfigurationElement {
        static let `default`: DelimiterConfiguration = .init(opening: "[", closing: "]")

        fileprivate(set) var opening: String
        fileprivate(set) var closing: String

        func asOption() -> OptionType {
            .nest {
                "opening" => .string(opening)
                "closing" => .string(closing)
            }
        }
    }

    @ConfigurationElement(key: "approaching_expiry_severity")
    private(set) var approachingExpirySeverity = Severity(.warning)
    @ConfigurationElement(key: "expired_severity")
    private(set) var expiredSeverity = Severity(.error)
    @ConfigurationElement(key: "bad_formatting_severity")
    private(set) var badFormattingSeverity = Severity(.error)

    // swiftlint:disable:next todo
    /// The number of days prior to expiry before the TODO emits a violation
    @ConfigurationElement(key: "approaching_expiry_threshold")
    private(set) var approachingExpiryThreshold = 15
    /// The opening/closing characters used to surround the expiry-date string
    @ConfigurationElement(key: "date_delimiters")
    private(set) var dateDelimiters = DelimiterConfiguration.default
    /// The format which should be used to the expiry-date string into a `Date` object
    @ConfigurationElement(key: "date_format")
    private(set) var dateFormat = "MM/dd/yyyy"
    /// The separator used for regex detection of the expiry-date string
    @ConfigurationElement(key: "date_separator")
    private(set) var dateSeparator = "/"

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let approachingExpiryConfiguration = configurationDict[$approachingExpirySeverity] {
            try approachingExpirySeverity.apply(configuration: approachingExpiryConfiguration)
        }
        if let expiredConfiguration = configurationDict[$expiredSeverity] {
            try expiredSeverity.apply(configuration: expiredConfiguration)
        }
        if let badFormattingConfiguration = configurationDict[$badFormattingSeverity] {
            try badFormattingSeverity.apply(configuration: badFormattingConfiguration)
        }
        if let approachingExpiryThreshold = configurationDict[$approachingExpiryThreshold] as? Int {
            self.approachingExpiryThreshold = approachingExpiryThreshold
        }
        if let dateFormat = configurationDict[$dateFormat] as? String {
            self.dateFormat = dateFormat
        }
        if let dateDelimiters = configurationDict[$dateDelimiters] as? [String: String] {
            if let openingDelimiter = dateDelimiters["opening"] {
                self.dateDelimiters.opening = openingDelimiter
            }
            if let closingDelimiter = dateDelimiters["closing"] {
                self.dateDelimiters.closing = closingDelimiter
            }
        }
        if let dateSeparator = configurationDict[$dateSeparator] as? String {
            self.dateSeparator = dateSeparator
        }
    }
}
