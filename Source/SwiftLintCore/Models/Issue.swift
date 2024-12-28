import Foundation

/// All possible SwiftLint issues which are printed as warnings by default.
public enum Issue: LocalizedError, Equatable {
    /// The configuration didn't match internal expectations.
    case invalidConfiguration(ruleID: String, message: String? = nil)

    /// Issued when a regular expression pattern is invalid.
    case invalidRegexPattern(ruleID: String, pattern: String)

    /// Issued when an option is deprecated. Suggests an alternative optionally.
    case deprecatedConfigurationOption(ruleID: String, key: String, alternative: String? = nil)

    /// Used in configuration parsing when no changes have been applied. Use only internally!
    case nothingApplied(ruleID: String)

    /// Rule is listed multiple times in the configuration.
    case listedMultipleTime(ruleID: String, times: Int)

    /// An identifier `old` has been renamed to `new`.
    case renamedIdentifier(old: String, new: String)

    /// Some configuration keys are invalid.
    case invalidConfigurationKeys(ruleID: String, keys: Set<String>)

    /// The configuration is inconsistent, that is options are mutually exclusive or one drives other values
    /// irrelevant.
    case inconsistentConfiguration(ruleID: String, message: String)

    /// Used rule IDs are invalid.
    case invalidRuleIDs(Set<String>)

    /// Found a rule configuration for a rule that is not present in `only_rules`.
    case ruleNotPresentInOnlyRules(ruleID: String)

    /// Found a rule configuration for a rule that is disabled.
    case ruleDisabledInDisabledRules(ruleID: String)

    /// Found a rule configuration for a rule that is disabled in the parent configuration.
    case ruleDisabledInParentConfiguration(ruleID: String)

    /// Found a rule configuration for a rule that is not enabled in `opt_in_rules`.
    case ruleNotEnabledInOptInRules(ruleID: String)

    /// Found a rule configuration for a rule that is not enabled in parent `only_rules`.
    case ruleNotEnabledInParentOnlyRules(ruleID: String)

    /// A generic warning specified by a string.
    case genericWarning(String)

    /// A generic error specified by a string.
    case genericError(String)

    /// A deprecation warning for a rule.
    case ruleDeprecated(ruleID: String)

    /// The initial configuration file was not found.
    case initialFileNotFound(path: String)

    /// A file at specified path was not found.
    case fileNotFound(path: String)

    /// The file at `path` is not readable or cannot be opened.
    case fileNotReadable(path: String?, ruleID: String)

    /// The file at `path` is not writable.
    case fileNotWritable(path: String)

    /// The file at `path` cannot be indexed by a specific rule.
    case indexingError(path: String?, ruleID: String)

    /// No arguments were provided to compile a file at `path` within a specific rule.
    case missingCompilerArguments(path: String?, ruleID: String)

    /// Cursor information cannot be extracted from a specific location.
    case missingCursorInfo(path: String?, ruleID: String)

    /// An error that occurred when parsing YAML.
    case yamlParsing(String)

    /// The baseline file at `path` is not readable or cannot be opened.
    case baselineNotReadable(path: String)

    /// Flag to enable warnings for deprecations being printed to the console. Printing is enabled by default.
    package nonisolated(unsafe) static var printDeprecationWarnings = true

    @TaskLocal private static var messageConsumer: (@Sendable (String) -> Void)?

    /// Hook used to capture all messages normally printed to stdout and return them back to the caller.
    ///
    /// > Warning: Shall only be used in tests to verify console output.
    ///
    /// - parameter runner: The code to run. Messages printed during the execution are collected.
    ///
    /// - returns: The collected messages produced while running the code in the runner.
    @MainActor
    static func captureConsole(runner: () throws -> Void) async rethrows -> String {
        actor Console {
            static var content = ""
        }
        defer {
            Console.content = ""
        }
        try $messageConsumer.withValue(
            { Console.content += (Console.content.isEmpty ? "" : "\n") + $0 },
            operation: runner
        )
        await Task.yield()
        return Console.content
    }

    /// Wraps any `Error` into a `SwiftLintError.genericWarning` if it is not already a `SwiftLintError`.
    ///
    /// - parameter error: Any `Error`.
    ///
    /// - returns: A `SwiftLintError.genericWarning` containing the message of the `error` argument.
    package static func wrap(error: some Error) -> Self {
        error as? Self ?? Self.genericWarning(error.localizedDescription)
    }

    /// Make this issue an error.
    package var asError: Self {
        Self.genericError(message)
    }

    /// The issues description which is ready to be printed to the console.
    package var errorDescription: String {
        switch self {
        case .genericError:
            return "error: \(message)"
        case .genericWarning:
            return "warning: \(message)"
        default:
            return Self.genericWarning(message).errorDescription
        }
    }

    /// Print the issue to the console.
    public func print() {
        if case .ruleDeprecated = self, !Self.printDeprecationWarnings {
            return
        }
        Task(priority: .high) { @MainActor in
            if let consumer = Self.messageConsumer {
                consumer(errorDescription)
            } else {
                queuedPrintError(errorDescription)
            }
        }
    }

    private var message: String {
        switch self {
        case let .invalidConfiguration(id, message):
            let message = if let message { ": \(message)" } else { "." }
            return "Invalid configuration for '\(id)' rule\(message) Falling back to default."
        case let .invalidRegexPattern(id, pattern):
            return "Invalid regular expression pattern '\(pattern)' used to configure '\(id)' rule."
        case let .deprecatedConfigurationOption(id, key, alternative):
            let baseMessage = "Configuration option '\(key)' in '\(id)' rule is deprecated."
            if let alternative {
                return baseMessage + " Use the option '\(alternative)' instead."
            }
            return baseMessage
        case let .nothingApplied(ruleID: id):
            return Self.invalidConfiguration(ruleID: id).message
        case let .listedMultipleTime(id, times):
            return "'\(id)' is listed \(times) times in the configuration."
        case let .renamedIdentifier(old, new):
            return "'\(old)' has been renamed to '\(new)' and will be completely removed in a future release."
        case let .invalidConfigurationKeys(id, keys):
            return "Configuration for '\(id)' rule contains the invalid key(s) \(keys.formatted)."
        case let .inconsistentConfiguration(id, message):
            return "Inconsistent configuration for '\(id)' rule: \(message)"
        case let .invalidRuleIDs(ruleIDs):
            return "The key(s) \(ruleIDs.formatted) used as rule identifier(s) is/are invalid."
        case let .ruleNotPresentInOnlyRules(id):
            return "Found a configuration for '\(id)' rule, but it is not present in 'only_rules'."
        case let .ruleDisabledInDisabledRules(id):
            return "Found a configuration for '\(id)' rule, but it is disabled in 'disabled_rules'."
        case let .ruleDisabledInParentConfiguration(id):
            return "Found a configuration for '\(id)' rule, but it is disabled in a parent configuration."
        case let .ruleNotEnabledInOptInRules(id):
            return "Found a configuration for '\(id)' rule, but it is not enabled in 'opt_in_rules'."
        case let .ruleNotEnabledInParentOnlyRules(id):
            return "Found a configuration for '\(id)' rule, but it is not present in the parent's 'only_rules'."
        case let .genericWarning(message), let .genericError(message):
            return message
        case let .ruleDeprecated(id):
            return """
                The `\(id)` rule is now deprecated and will be \
                completely removed in a future release.
                """
        case let .initialFileNotFound(path):
            return "Could not read file at path '\(path)'."
        case let .fileNotFound(path):
            return "File at path '\(path)' not found."
        case let .fileNotReadable(path, id):
            return "Cannot open or read file at path '\(path ?? "...")' within '\(id)' rule."
        case let .fileNotWritable(path):
            return "Cannot write to file at path '\(path)'."
        case let .indexingError(path, id):
            return "Cannot index file at path '\(path ?? "...")' within '\(id)' rule."
        case let .missingCompilerArguments(path, id):
            return """
                Attempted to lint file at path '\(path ?? "...")' within '\(id)' rule \
                without any compiler arguments.
                """
        case let .missingCursorInfo(path, id):
            return "Cannot get cursor info from file at path '\(path ?? "...")' within '\(id)' rule."
        case let .yamlParsing(message):
            return "Cannot parse YAML file: \(message)"
        case let .baselineNotReadable(path):
            return "Cannot open or read the baseline file at path '\(path)'."
        }
    }
}

private extension Set where Element == String {
    var formatted: String {
        sorted()
            .map { "'\($0)'" }
            .joined(separator: ", ")
    }
}
