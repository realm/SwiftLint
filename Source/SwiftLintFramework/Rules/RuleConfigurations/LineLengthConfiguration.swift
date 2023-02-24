struct LineLengthRuleOptions: OptionSet {
    let rawValue: Int

    init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }

    static let ignoreURLs = Self(rawValue: 1 << 0)
    static let ignoreFunctionDeclarations = Self(rawValue: 1 << 1)
    static let ignoreComments = Self(rawValue: 1 << 2)
    static let ignoreInterpolatedStrings = Self(rawValue: 1 << 3)
}

private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresURLs = "ignores_urls"
    case ignoresFunctionDeclarations = "ignores_function_declarations"
    case ignoresComments = "ignores_comments"
    case ignoresInterpolatedStrings = "ignores_interpolated_strings"
}

struct LineLengthConfiguration: RuleConfiguration, Equatable {
    var consoleDescription: String {
        return length.consoleDescription +
               ", ignores_urls: \(ignoresURLs)" +
               ", ignores_function_declarations: \(ignoresFunctionDeclarations)" +
               ", ignores_comments: \(ignoresComments)" +
               ", ignores_interpolated_strings: \(ignoresInterpolatedStrings)"
    }

    var length: SeverityLevelsConfiguration
    var ignoresURLs: Bool
    var ignoresFunctionDeclarations: Bool
    var ignoresComments: Bool
    var ignoresInterpolatedStrings: Bool

    var params: [RuleParameter<Int>] {
        return length.params
    }

    init(warning: Int, error: Int?, options: LineLengthRuleOptions = []) {
        self.length = SeverityLevelsConfiguration(warning: warning, error: error)
        self.ignoresURLs = options.contains(.ignoreURLs)
        self.ignoresFunctionDeclarations = options.contains(.ignoreFunctionDeclarations)
        self.ignoresComments = options.contains(.ignoreComments)
        self.ignoresInterpolatedStrings = options.contains(.ignoreInterpolatedStrings)
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
        let error = ConfigurationError.unknownConfiguration
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
