import Foundation

/// All possible SwiftLint issues which are printed as warnings by default.
public enum Issue: LocalizedError, Equatable {
    /// The configuration didn't match internal expectations.
    case unknownConfiguration(ruleID: String)

    /// Rule is listed multiple times in the configuration.
    case listedMultipleTime(ruleID: String, times: Int)

    /// An identifier `old` has been renamed to `new`.
    case renamedIdentifier(old: String, new: String)

    /// Configuration for a rule is invalid.
    case invalidConfiguration(ruleID: String)

    /// Some configuration keys are invalid.
    case invalidConfigurationKeys([String])

    /// A generic warning specified by a string.
    case genericWarning(String)

    /// A generic error specified by a string.
    case genericError(String)

    /// A deprecation warning for a rule.
    case ruleDeprecated(ruleID: String)

    /// The initial configuration file was not found.
    case initialFileNotFound(path: String)

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

    /// Flag to enable warnings for deprecations being printed to the console. Printing is enabled by default.
    public static var printDeprecationWarnings = true

    /// Wraps any `Error` into a `SwiftLintError.genericWarning` if it is not already a `SwiftLintError`.
    ///
    /// - parameter error: Any `Error`.
    ///
    /// - returns: A `SwiftLintError.genericWarning` containig the message of the `error` argument.
    static func wrap(error: Error) -> Self {
        error as? Issue ?? Self.genericWarning(error.localizedDescription)
    }

    /// Make this issue an error.
    var asError: Self {
        Self.genericError(message)
    }

    /// The issues description which is ready to be printed to the console.
    var errorDescription: String {
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
        queuedPrintError(errorDescription)
    }

    private var message: String {
        switch self {
        case let .unknownConfiguration(id):
            return "Invalid configuration for '\(id)' rule. Falling back to default."
        case let .listedMultipleTime(id, times):
            return "'\(id)' is listed \(times) times in the configuration."
        case let .renamedIdentifier(old, new):
            return "'\(old)' has been renamed to '\(new)' and will be completely removed in a future release."
        case let .invalidConfiguration(id):
            return "Invalid configuration for '\(id)'. Falling back to default."
        case let .invalidConfigurationKeys(keys):
            return "Configuration contains invalid keys \(keys.joined(separator: ", "))."
        case let .genericWarning(message), let .genericError(message):
            return message
        case let .ruleDeprecated(id):
            return """
                The `\(id)` rule is now deprecated and will be \
                completely removed in a future release.
                """
        case let .initialFileNotFound(path):
            return "Could not read file at path '\(path)'."
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
        }
    }
}
