public enum ConfigurationError: Error, Equatable {
    case unknownConfiguration
    case generic(String)
}
