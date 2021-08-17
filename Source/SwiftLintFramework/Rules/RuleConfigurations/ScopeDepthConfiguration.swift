public struct ScopeDepthConfiguration: RuleConfiguration, Equatable {
    private(set) var warningDepth: Int
    private(set) var errorDepth: Int

    public var consoleDescription: String {
        return "warningDepth: \(warningDepth), errorDepth: \(errorDepth)"
    }

    public init(warningDepth: Int, errorDepth: Int) {
        self.warningDepth = warningDepth
        self.errorDepth = errorDepth
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationData = configuration as? [String: Int] else {
            throw ConfigurationError.unknownConfiguration
        }

        guard let warningDepthValue = configurationData["warning"] else {
            throw ConfigurationError.unknownConfiguration
        }

        guard let errorDepthValue = configurationData["error"] else {
            throw ConfigurationError.unknownConfiguration
        }

        guard warningDepthValue <= errorDepthValue else {
            throw ConfigurationError.generic("warning depth should be less than or equal to the error depth")
        }

        warningDepth = warningDepthValue
        errorDepth = errorDepthValue
    }
}
