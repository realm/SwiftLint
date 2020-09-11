/// All possible configuration errors.
public enum ConfigurationError: Error {
    /// The configuration didn't match internal expectations.
    case unknownConfiguration
    /// The configuration had both `match_kind` and `excluded_match_kind` parameters.
    case ambiguousMatchKindParameters
}
