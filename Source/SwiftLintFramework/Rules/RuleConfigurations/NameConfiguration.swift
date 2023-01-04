import Foundation

struct NameConfiguration: RuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(min_length) \(minLength.shortConsoleDescription), " +
            "(max_length) \(maxLength.shortConsoleDescription), " +
            "excluded: \(excludedRegularExpressions.map { $0.regex.pattern }.sorted()), " +
            "allowed_symbols: \(allowedSymbolsSet.sorted()), " +
            "validates_start_with_lowercase: \(validatesStartWithLowercase)"
    }

    var minLength: SeverityLevelsConfiguration
    var maxLength: SeverityLevelsConfiguration
    var excludedRegularExpressions: Set<ExcludedRegexExpression>
    private var allowedSymbolsSet: Set<String>
    var validatesStartWithLowercase: Bool

    var minLengthThreshold: Int {
        return max(minLength.warning, minLength.error ?? minLength.warning)
    }

    var maxLengthThreshold: Int {
        return min(maxLength.warning, maxLength.error ?? maxLength.warning)
    }

    var allowedSymbols: CharacterSet {
        return CharacterSet(charactersIn: allowedSymbolsSet.joined())
    }

    init(minLengthWarning: Int,
         minLengthError: Int,
         maxLengthWarning: Int,
         maxLengthError: Int,
         excluded: [String] = [],
         allowedSymbols: [String] = [],
         validatesStartWithLowercase: Bool = true) {
        minLength = SeverityLevelsConfiguration(warning: minLengthWarning, error: minLengthError)
        maxLength = SeverityLevelsConfiguration(warning: maxLengthWarning, error: maxLengthError)
        self.excludedRegularExpressions = Set(excluded.compactMap { ExcludedRegexExpression(pattern: "^\($0)$") })
        self.allowedSymbolsSet = Set(allowedSymbols)
        self.validatesStartWithLowercase = validatesStartWithLowercase
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let minLengthConfiguration = configurationDict["min_length"] {
            try minLength.apply(configuration: minLengthConfiguration)
        }
        if let maxLengthConfiguration = configurationDict["max_length"] {
            try maxLength.apply(configuration: maxLengthConfiguration)
        }
        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excludedRegularExpressions = Set(excluded.compactMap { ExcludedRegexExpression(pattern: "^\($0)$") })
        }
        if let allowedSymbols = [String].array(of: configurationDict["allowed_symbols"]) {
            self.allowedSymbolsSet = Set(allowedSymbols)
        }

        if let validatesStartWithLowercase = configurationDict["validates_start_with_lowercase"] as? Bool {
            self.validatesStartWithLowercase = validatesStartWithLowercase
        } else if let validatesStartWithLowercase = configurationDict["validates_start_lowercase"] as? Bool {
            self.validatesStartWithLowercase = validatesStartWithLowercase
            queuedPrintError("\"validates_start_lowercase\" configuration was renamed to " +
                "\"validates_start_with_lowercase\" and will be removed in a future release.")
        }
    }
}

// MARK: - ConfigurationProviderRule extensions

extension ConfigurationProviderRule where ConfigurationType == NameConfiguration {
    func severity(forLength length: Int) -> ViolationSeverity? {
        return configuration.severity(forLength: length)
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
        return excludedRegularExpressions.contains(where: {
            return !$0.regex.matches(in: name, options: [], range: NSRange(name.startIndex..., in: name)).isEmpty
        })
    }
}
