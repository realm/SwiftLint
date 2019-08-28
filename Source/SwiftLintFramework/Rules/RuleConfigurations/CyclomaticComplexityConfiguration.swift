import SourceKittenFramework

private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresCaseStatements = "ignores_case_statements"
}

public struct CyclomaticComplexityConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return length.consoleDescription +
            ", \(ConfigurationKey.ignoresCaseStatements.rawValue): \(ignoresCaseStatements)"
    }

    public static let defaultComplexityStatements: Set<StatementKind> = [
        .forEach,
        .if,
        .guard,
        .for,
        .repeatWhile,
        .while,
        .case
    ]

    public private(set) var length: SeverityLevelsConfiguration

    public private(set) var complexityStatements: Set<StatementKind>

    public private(set) var ignoresCaseStatements: Bool {
        didSet {
            if ignoresCaseStatements {
                complexityStatements.remove(.case)
            } else {
                complexityStatements.insert(.case)
            }
        }
    }

    var params: [RuleParameter<Int>] {
        return length.params
    }

    public init(warning: Int, error: Int?, ignoresCaseStatements: Bool = false) {
        self.length = SeverityLevelsConfiguration(warning: warning, error: error)
        self.complexityStatements = type(of: self).defaultComplexityStatements
        self.ignoresCaseStatements = ignoresCaseStatements
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration),
            !configurationArray.isEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            length = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], !configDict.isEmpty {
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                switch (key, value) {
                case (.error, let intValue as Int):
                    length.error = intValue
                case (.warning, let intValue as Int):
                    length.warning = intValue
                case (.ignoresCaseStatements, let boolValue as Bool):
                    ignoresCaseStatements = boolValue
                default:
                    throw ConfigurationError.unknownConfiguration
                }
            }
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}
