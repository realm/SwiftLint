import Foundation

struct NameConfiguration: RuleConfiguration, Equatable {
    var consoleDescription: String {
        var output = "(min_length) \(minLength.shortConsoleDescription), " +
            "(max_length) \(maxLength.shortConsoleDescription), " +
            "excluded: \(excludedRegularExpressions.map { $0.pattern }.sorted()), " +
            "allowed_symbols: \(allowedSymbolsSet.sorted())"
        if let requiresCaseCheck = validatesStartWithLowercase {
            output += ", validates_start_with_lowercase: \(requiresCaseCheck.severity)"
        }
        return output
    }

    var minLength: SeverityLevelsConfiguration
    var maxLength: SeverityLevelsConfiguration
    var excludedRegularExpressions: Set<NSRegularExpression>
    private var allowedSymbolsSet: Set<String>
    var validatesStartWithLowercase: SeverityConfiguration?

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
         validatesStartWithLowercase: SeverityConfiguration? = .error) {
        minLength = SeverityLevelsConfiguration(warning: minLengthWarning, error: minLengthError)
        maxLength = SeverityLevelsConfiguration(warning: maxLengthWarning, error: maxLengthError)
        self.excludedRegularExpressions = Set(excluded.compactMap {
            try? NSRegularExpression.cached(pattern: "^\($0)$")
        })
        self.allowedSymbolsSet = Set(allowedSymbols)
        self.validatesStartWithLowercase = validatesStartWithLowercase
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration
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
            self.allowedSymbolsSet = Set(allowedSymbols)
        }

        if let validatesStartWithLowercase = configurationDict["validates_start_with_lowercase"] as? String {
            var severity = SeverityConfiguration.warning
            try severity.apply(configuration: validatesStartWithLowercase)
            self.validatesStartWithLowercase = severity
        } else if let validatesStartWithLowercase = configurationDict["validates_start_with_lowercase"] as? Bool {
            // TODO: [05/10/2025] Remove deprecation warning after ~2 years.
            self.validatesStartWithLowercase = validatesStartWithLowercase ? .error : nil
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
        excludedRegularExpressions.contains {
            !$0.matches(in: name, options: [], range: NSRange(name.startIndex..., in: name)).isEmpty
        }
    }
}
