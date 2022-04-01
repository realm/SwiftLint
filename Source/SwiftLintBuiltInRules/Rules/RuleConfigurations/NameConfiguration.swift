import Foundation

struct NameConfiguration<Parent: Rule>: RuleConfiguration, Equatable {
    typealias Severity = SeverityConfiguration<Parent>
    typealias SeverityLevels = SeverityLevelsConfiguration<Parent>
    typealias StartWithLowercaseConfiguration = ChildOptionSeverityConfiguration<Parent>

    var parameterDescription: RuleConfigurationDescription {
        "(min_length)" => .nested(minLength.parameterDescription)
        "(max_length)" => .nested(maxLength.parameterDescription)
        "excluded" => .list(excludedRegularExpressions.map(\.pattern).sorted().map { .symbol($0) })
        "allowed_symbols" => .list(allowedSymbols.sorted().map { .string($0) })
        "unallowed_symbols_severity" => .severity(unallowedSymbolsSeverity.severity)
        "validates_start_with_lowercase" => .symbol(validatesStartWithLowercase.severity?.rawValue ?? "off")
    }

    private(set) var minLength: SeverityLevels
    private(set) var maxLength: SeverityLevels
    private(set) var excludedRegularExpressions: Set<NSRegularExpression>
    private(set) var allowedSymbols: Set<String>
    private(set) var unallowedSymbolsSeverity: Severity
    private(set) var validatesStartWithLowercase: StartWithLowercaseConfiguration

    var minLengthThreshold: Int {
        return max(minLength.warning, minLength.error ?? minLength.warning)
    }

    var maxLengthThreshold: Int {
        return min(maxLength.warning, maxLength.error ?? maxLength.warning)
    }

    var allowedSymbolsAndAlphanumerics: CharacterSet {
        CharacterSet(charactersIn: allowedSymbols.joined()).union(.alphanumerics)
    }

    init(minLengthWarning: Int,
         minLengthError: Int,
         maxLengthWarning: Int,
         maxLengthError: Int,
         excluded: [String] = [],
         allowedSymbols: [String] = [],
         unallowedSymbolsSeverity: Severity = .error,
         validatesStartWithLowercase: StartWithLowercaseConfiguration = .error) {
        minLength = SeverityLevels(warning: minLengthWarning, error: minLengthError)
        maxLength = SeverityLevels(warning: maxLengthWarning, error: maxLengthError)
        self.excludedRegularExpressions = Set(excluded.compactMap {
            try? NSRegularExpression.cached(pattern: "^\($0)$")
        })
        self.allowedSymbols = Set(allowedSymbols)
        self.unallowedSymbolsSeverity = unallowedSymbolsSeverity
        self.validatesStartWithLowercase = validatesStartWithLowercase
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let minLengthConfiguration = configurationDict["min_length"] {
            try minLength.apply(configuration: minLengthConfiguration)
        }
        if let maxLengthConfiguration = configurationDict["max_length"] {
            try maxLength.apply(configuration: maxLengthConfiguration)
        }
        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excludedRegularExpressions = Set(excluded.compactMap {
                try? NSRegularExpression.cached(pattern: "^\($0)$")
            })
        }
        if let allowedSymbols = [String].array(of: configurationDict["allowed_symbols"]) {
            self.allowedSymbols = Set(allowedSymbols)
        }
        if let unallowedSymbolsSeverity = configurationDict["unallowed_symbols_severity"] {
            try self.unallowedSymbolsSeverity.apply(configuration: unallowedSymbolsSeverity)
        }
        if let validatesStartWithLowercase = configurationDict["validates_start_with_lowercase"] as? String {
            try self.validatesStartWithLowercase.apply(configuration: validatesStartWithLowercase)
        } else if let validatesStartWithLowercase = configurationDict["validates_start_with_lowercase"] as? Bool {
            // TODO: [05/10/2025] Remove deprecation warning after ~2 years.
            self.validatesStartWithLowercase = validatesStartWithLowercase ? .error : .off
            Issue.genericWarning(
                """
                The \"validates_start_with_lowercase\" configuration now expects a severity (warning or \
                error). The boolean value 'true' will still enable it as an error. It is now deprecated and will be \
                removed in a future release.
                """
            ).print()
        }
    }
}

extension NameConfiguration {
    func severity(forLength length: Int) -> ViolationSeverity? {
        if let minError = minLength.error, length < minError {
            return .error
        } else if let maxError = maxLength.error, length > maxError {
            return .error
        } else if length < minLength.warning ||
                  length > maxLength.warning {
            return .warning
        }
        return nil
    }
}

// MARK: - `exclude` option extensions

extension NameConfiguration {
    func shouldExclude(name: String) -> Bool {
        excludedRegularExpressions.contains {
            !$0.matches(in: name, options: [], range: NSRange(name.startIndex..., in: name)).isEmpty
        }
    }
}
