import Foundation

/// All possible SwiftLint issues which are printed as warnings by default.
public enum Issue: LocalizedError, Equatable {
    /// The configuration didn't match internal expectations.
    case unknownConfiguration

    /// A generic warning specified by a string.
    case genericWarning(String)

    /// A deprecation warning for a rule.
    case deprecation(ruleID: String)

    /// The initial configuration file was not found.
    case initialFileNotFound(path: String)

    /// An error that occurred when parsing YAML.
    case yamlParsing(String)

    /// The issues description which is ready to be printed to the console.
    var errorDescription: String {
        switch self {
        case .genericWarning:
            return "warning: \(message)"
        default:
            return Self.genericWarning(message).errorDescription
        }
    }

    private var message: String {
        switch self {
        case .unknownConfiguration:
            return "Invalid configuration. Falling back to default."
        case .genericWarning(let message):
            return "\(message)"
        case .deprecation(let ruleID):
            return """
                The `\(ruleID)` rule is now deprecated and will be \
                completely removed in a future release.
                """
        case .initialFileNotFound(let path):
            return "Could not read file at path \(path)."
        case .yamlParsing(let message):
            return "Cannot parse YAML file: \(message)"
        }
    }
}
