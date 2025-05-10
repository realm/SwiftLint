import Foundation
import SwiftLintCore

struct NameConfiguration<Parent: Rule>: RuleConfiguration, InlinableOptionType {
    typealias Severity = SeverityConfiguration<Parent>
    typealias SeverityLevels = SeverityLevelsConfiguration<Parent>
    typealias StartWithLowercaseConfiguration = ChildOptionSeverityConfiguration<Parent>

    @ConfigurationElement(key: "min_length")
    private(set) var minLength = SeverityLevels(warning: 0, error: 0)
    @ConfigurationElement(key: "max_length")
    private(set) var maxLength = SeverityLevels(warning: 0, error: 0)
    @ConfigurationElement(key: "excluded")
    private(set) var excludedRegularExpressions = Set<RegularExpression>()
    @ConfigurationElement(key: "allowed_symbols")
    private(set) var allowedSymbols = Set<String>()
    @ConfigurationElement(key: "unallowed_symbols_severity")
    private(set) var unallowedSymbolsSeverity = Severity.error
    @ConfigurationElement(key: "validates_start_with_lowercase")
    private(set) var validatesStartWithLowercase = StartWithLowercaseConfiguration.error

    var minLengthThreshold: Int {
        max(minLength.warning, minLength.error ?? minLength.warning)
    }

    var maxLengthThreshold: Int {
        min(maxLength.warning, maxLength.error ?? maxLength.warning)
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
            try? RegularExpression(pattern: "^\($0)$")
        })
        self.allowedSymbols = Set(allowedSymbols)
        self.unallowedSymbolsSeverity = unallowedSymbolsSeverity
        self.validatesStartWithLowercase = validatesStartWithLowercase
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }

        if let minLengthConfiguration = configurationDict[$minLength.key] {
            try minLength.apply(configuration: minLengthConfiguration)
        }
        if let maxLengthConfiguration = configurationDict[$maxLength.key] {
            try maxLength.apply(configuration: maxLengthConfiguration)
        }
        if let excluded = [String].array(of: configurationDict[$excludedRegularExpressions.key]) {
            self.excludedRegularExpressions = Set(excluded.compactMap {
                try? RegularExpression(pattern: "^\($0)$")
            })
        }
        if let allowedSymbols = [String].array(of: configurationDict[$allowedSymbols.key]) {
            self.allowedSymbols = Set(allowedSymbols)
        }
        if let unallowedSymbolsSeverity = configurationDict[$unallowedSymbolsSeverity.key] {
            try self.unallowedSymbolsSeverity.apply(configuration: unallowedSymbolsSeverity)
        }
        if let validatesStartWithLowercase = configurationDict[$validatesStartWithLowercase.key] as? String {
            try self.validatesStartWithLowercase.apply(configuration: validatesStartWithLowercase)
        } else if let validatesStartWithLowercase = configurationDict[$validatesStartWithLowercase.key] as? Bool {
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
        }
        if let maxError = maxLength.error, length > maxError {
            return .error
        }
        if length < minLength.warning || length > maxLength.warning {
            return .warning
        }
        return nil
    }

    func containsOnlyAllowedCharacters(name: String) -> Bool {
        allowedSymbolsAndAlphanumerics.isSuperset(of: CharacterSet(charactersIn: name))
    }
}

// MARK: - `exclude` option extensions

extension NameConfiguration {
    func shouldExclude(name: String) -> Bool {
        excludedRegularExpressions.contains {
            !$0.regex.matches(in: name, options: [], range: NSRange(name.startIndex..., in: name)).isEmpty
        }
    }
}
