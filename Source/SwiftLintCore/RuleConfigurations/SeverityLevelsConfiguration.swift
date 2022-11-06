/// A rule configuration that allows specifying thresholds for `warning` and `error` severities.
public struct SeverityLevelsConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        let errorString: String
        if let errorValue = error {
            errorString = ", error: \(errorValue)"
        } else {
            errorString = ""
        }
        return "warning: \(warning)" + errorString
    }

    /// A condensed console description.
    public var shortConsoleDescription: String {
        if let errorValue = error {
            return "w/e: \(warning)/\(errorValue)"
        }
        return "w: \(warning)"
    }

    /// The threshold for a violation to be a warning.
    public var warning: Int
    /// The threshold for a violation to be an error.
    public var error: Int?

    /// Create a `SeverityLevelsConfiguration` based on the sepecified `warning` and `error` thresholds.
    ///
    /// - parameter warning: The threshold for a violation to be a warning.
    /// - parameter error:   The threshold for a violation to be an error.
    public init(warning: Int, error: Int? = nil) {
        self.warning = warning
        self.error = error
    }

    /// The rule parameters that define the thresholds that should map to each severity.
    public var params: [RuleParameter<Int>] {
        if let error = error {
            return [RuleParameter(severity: .error, value: error),
                    RuleParameter(severity: .warning, value: warning)]
        }
        return [RuleParameter(severity: .warning, value: warning)]
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration), configurationArray.isNotEmpty {
            warning = configurationArray[0]
            error = (configurationArray.count > 1) ? configurationArray[1] : nil
        } else if let configDict = configuration as? [String: Int?],
            configDict.isNotEmpty, Set(configDict.keys).isSubset(of: ["warning", "error"]) {
            warning = (configDict["warning"] as? Int) ?? warning
            error = configDict["error"] as? Int
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}
