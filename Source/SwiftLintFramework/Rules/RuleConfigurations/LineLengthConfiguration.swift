public struct LineLengthRuleOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }

    public static let ignoreURLs = LineLengthRuleOptions(rawValue: 1 << 0)
    public static let ignoreFunctionDeclarations = LineLengthRuleOptions(rawValue: 1 << 1)
    public static let ignoreComments = LineLengthRuleOptions(rawValue: 1 << 2)
    public static let ignoreInterpolatedStrings = LineLengthRuleOptions(rawValue: 1 << 3)

    public static let all: LineLengthRuleOptions = [.ignoreURLs,
                                                    .ignoreFunctionDeclarations,
                                                    .ignoreComments,
                                                    .ignoreInterpolatedStrings]
}

private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresURLs = "ignores_urls"
    case ignoresFunctionDeclarations = "ignores_function_declarations"
    case ignoresComments = "ignores_comments"
    case ignoresInterpolatedStrings = "ignores_interpolated_strings"
}

public struct LineLengthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return length.consoleDescription +
               ", ignores urls: \(ignoresURLs)" +
               ", ignores function declarations: \(ignoresFunctionDeclarations)" +
               ", ignores comments: \(ignoresComments)" +
               ", ignores interpolated strings: \(ignoresInterpolatedStrings)"
    }

    var length: SeverityLevelsConfiguration
    var ignoresURLs: Bool
    var ignoresFunctionDeclarations: Bool
    var ignoresComments: Bool
    var ignoresInterpolatedStrings: Bool

    var params: [RuleParameter<Int>] {
        return length.params
    }

    public init(warning: Int, error: Int?, options: LineLengthRuleOptions = []) {
        self.length = SeverityLevelsConfiguration(warning: warning, error: error)
        self.ignoresURLs = options.contains(.ignoreURLs)
        self.ignoresFunctionDeclarations = options.contains(.ignoreFunctionDeclarations)
        self.ignoresComments = options.contains(.ignoreComments)
        self.ignoresInterpolatedStrings = options.contains(.ignoreInterpolatedStrings)
    }

    public mutating func apply(configuration: Any) throws {
        if applyArray(configuration: configuration) {
            return
        }
        try applyDictionary(configuration: configuration)
    }

    /// Applies configuration as an array of integers. Returns true if did apply.
    private mutating func applyArray(configuration: Any) -> Bool {
        guard let configurationArray = [Int].array(of: configuration),
            !configurationArray.isEmpty else {
            return false
        }

        let warning = configurationArray[0]
        let error = (configurationArray.count > 1) ? configurationArray[1] : nil
        length = SeverityLevelsConfiguration(warning: warning, error: error)
        return true
    }

    /// Applies configuration as a dictionary. Throws if configuration couldn't be applied.
    private mutating func applyDictionary(configuration: Any) throws {
        let error = ConfigurationError.unknownConfiguration
        guard let configDict = configuration as? [String: Any],
            !configDict.isEmpty else {
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

    public static func == (lhs: LineLengthConfiguration, rhs: LineLengthConfiguration) -> Bool {
        return lhs.length == rhs.length &&
            lhs.ignoresURLs == rhs.ignoresURLs &&
            lhs.ignoresComments == rhs.ignoresComments &&
            lhs.ignoresFunctionDeclarations == rhs.ignoresFunctionDeclarations &&
            lhs.ignoresInterpolatedStrings == rhs.ignoresInterpolatedStrings
    }
}
