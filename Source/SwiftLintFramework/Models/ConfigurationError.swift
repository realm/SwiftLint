/// All possible configuration errors.
public enum ConfigurationError: Error, Equatable {
    /// The configuration didn't match internal expectations.
    case unknownConfiguration

    /// The configuration had both `match_kind` and `excluded_match_kind` parameters.
    case ambiguousMatchKindParameters

    /// A generic configuration error specified by a string.
    case generic(String)

    /// An error for a configuration file that was not found on disk.
    case fileNotFound(path: String)
}
