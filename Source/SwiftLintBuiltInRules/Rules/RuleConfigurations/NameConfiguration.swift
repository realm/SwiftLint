import Foundation
import SwiftLintCore

struct NameConfiguration<Parent: Rule>: RuleConfiguration, Equatable {
    typealias Severity = SeverityConfiguration<Parent>
    typealias SeverityLevels = SeverityLevelsConfiguration<Parent>
    typealias StartWithLowercaseConfiguration = ChildOptionSeverityConfiguration<Parent>

    @ConfigurationElement(key: "min_length")
    private(set) var minLength = SeverityLevels(warning: 0, error: 0)
    @ConfigurationElement(key: "max_length")
    private(set) var maxLength = SeverityLevels(warning: 0, error: 0)
    @ConfigurationElement(key: "excluded")
    private(set) var excludedRegularExpressions = Set<NSRegularExpression>()
    @ConfigurationElement(key: "allowed_symbols")
    private(set) var allowedSymbols = Set<String>()
    @ConfigurationElement(key: "unallowed_symbols_severity")
    private(set) var unallowedSymbolsSeverity = Severity.error
    @ConfigurationElement(key: "validates_start_with_lowercase")
    private(set) var validatesStartWithLowercase = StartWithLowercaseConfiguration.error
    /// Only valid for `identifier_name`
    @ConfigurationElement(key: "ignore_min_length_for_short_closure_content")
    private(set) var ignoreMinLengthForShortClosureContent = false
    /// Only valid for `identifier_name`
    /// Before this update, the code skipped over functions in evaluating both their length and their special
    /// characters. The code read `if !SwiftDeclarationKind.functionKinds.contains(kind) {` which is incredibly hard
    /// to follow double negative logic, plus the description for the rule made no indication that functions were
    /// excluded from this rule. And given the history of this rule as previously being variables only, but refactored
    /// to the generic concept of identifiers (which should include function *identifiers*, this leads me to believe it
    /// was unintentional. Hence, I'm defaulting to `false`.
    @ConfigurationElement(key: "previous_function_behavior")
    private(set) var previousFunctionBehavior = false

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
         validatesStartWithLowercase: StartWithLowercaseConfiguration = .error,
         ignoreMinLengthForShortClosureContent: Bool = false,
         previousFunctionBehavior: Bool = false) {
        minLength = SeverityLevels(warning: minLengthWarning, error: minLengthError)
        maxLength = SeverityLevels(warning: maxLengthWarning, error: maxLengthError)
        self.excludedRegularExpressions = Set(excluded.compactMap {
            try? NSRegularExpression.cached(pattern: "^\($0)$")
        })
        self.allowedSymbols = Set(allowedSymbols)
        self.unallowedSymbolsSeverity = unallowedSymbolsSeverity
        self.validatesStartWithLowercase = validatesStartWithLowercase
        self.ignoreMinLengthForShortClosureContent = ignoreMinLengthForShortClosureContent
        self.previousFunctionBehavior = previousFunctionBehavior
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let minLengthConfiguration = configurationDict[$minLength] {
            try minLength.apply(configuration: minLengthConfiguration)
        }
        if let maxLengthConfiguration = configurationDict[$maxLength] {
            try maxLength.apply(configuration: maxLengthConfiguration)
        }
        if let excluded = [String].array(of: configurationDict[$excludedRegularExpressions]) {
            self.excludedRegularExpressions = Set(excluded.compactMap {
                try? NSRegularExpression.cached(pattern: "^\($0)$")
            })
        }
        if let allowedSymbols = [String].array(of: configurationDict[$allowedSymbols]) {
            self.allowedSymbols = Set(allowedSymbols)
        }
        if let unallowedSymbolsSeverity = configurationDict[$unallowedSymbolsSeverity] {
            try self.unallowedSymbolsSeverity.apply(configuration: unallowedSymbolsSeverity)
        }
        if let validatesStartWithLowercase = configurationDict[$validatesStartWithLowercase] as? String {
            try self.validatesStartWithLowercase.apply(configuration: validatesStartWithLowercase)
        } else if let validatesStartWithLowercase = configurationDict[$validatesStartWithLowercase] as? Bool {
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
        if let ignoreMinLengthForClosures = configurationDict[$ignoreMinLengthForShortClosureContent] as? Bool {
            self.ignoreMinLengthForShortClosureContent = ignoreMinLengthForClosures
        }
        if let previousFunctionBehavior = configurationDict[$previousFunctionBehavior] as? Bool {
            self.previousFunctionBehavior = previousFunctionBehavior
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
