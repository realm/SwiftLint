/// All possible configuration errors.
public enum ConfigurationError: Error, Equatable {
    /// The configuration didn't match internal expectations.
    case unknownConfiguration

    /// A generic configuration error specified by a string.
    case generic(String)
}
