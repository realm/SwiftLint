private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresURLs = "ignores_urls"
    case ignoresFunctionDeclarations = "ignores_function_declarations"
    case ignoresComments = "ignores_comments"
    case ignoresInterpolatedStrings = "ignores_interpolated_strings"
}

struct LineLengthConfiguration: RuleConfiguration, Equatable {
    typealias Parent = LineLengthRule

    var consoleDescription: String {
        return length.consoleDescription +
               ", ignores_urls: \(ignoresURLs)" +
               ", ignores_function_declarations: \(ignoresFunctionDeclarations)" +
               ", ignores_comments: \(ignoresComments)" +
               ", ignores_interpolated_strings: \(ignoresInterpolatedStrings)"
    }

    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 120, error: 200)
    private(set) var ignoresURLs = false
    private(set) var ignoresFunctionDeclarations = false
    private(set) var ignoresComments = false
    private(set) var ignoresInterpolatedStrings = false

    var params: [RuleParameter<Int>] {
        return length.params
    }

    mutating func apply(configuration: Any) throws {
        if applyArray(configuration: configuration) {
            return
        }
        try applyDictionary(configuration: configuration)
    }

    /// Applies configuration as an array of integers. Returns true if did apply.
    ///
    /// - parameter configuration: The untyped configuration value to apply.
    ///
    /// - returns: True if the configuration was successfuly applied.
    private mutating func applyArray(configuration: Any) -> Bool {
        guard let configurationArray = [Int].array(of: configuration),
            configurationArray.isNotEmpty else {
            return false
        }

        let warning = configurationArray[0]
        let error = (configurationArray.count > 1) ? configurationArray[1] : nil
        length = SeverityLevelsConfiguration(warning: warning, error: error)
        return true
    }

    /// Applies configuration as a dictionary. Throws if configuration couldn't be applied.
    ///
    /// - parameter configuration: The untyped configuration value to apply.
    ///
    /// - throws: Throws if the configuration value isn't properly formatted.
    private mutating func applyDictionary(configuration: Any) throws {
        let error = Issue.unknownConfiguration(ruleID: Parent.identifier)
        guard let configDict = configuration as? [String: Any],
            configDict.isNotEmpty else {
            throw error
        }

        for (string, value) in configDict {
            guard let key = ConfigurationKey(rawValue: string) else {
                throw error
            }
            switch (key, value) {
            case (.error, let intValue as Int):
                length.error = intValue
            case (.warning, let intValue as Int):
                length.warning = intValue
            case (.ignoresFunctionDeclarations, let boolValue as Bool):
                ignoresFunctionDeclarations = boolValue
            case (.ignoresComments, let boolValue as Bool):
                ignoresComments = boolValue
            case (.ignoresURLs, let boolValue as Bool):
                ignoresURLs = boolValue
            case (.ignoresInterpolatedStrings, let boolValue as Bool):
                ignoresInterpolatedStrings = boolValue
            default:
                throw error
            }
        }
    }
}
