import SourceKittenFramework

private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresCaseStatements = "ignores_case_statements"
}

struct CyclomaticComplexityConfiguration: RuleConfiguration, Equatable {
    typealias Parent = CyclomaticComplexityRule

    var consoleDescription: String {
        return length.consoleDescription +
            ", \(ConfigurationKey.ignoresCaseStatements.rawValue): \(ignoresCaseStatements)"
    }

    private static let defaultComplexityStatements: Set<StatementKind> = [
        .forEach,
        .if,
        .guard,
        .for,
        .repeatWhile,
        .while,
        .case
    ]

    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 10, error: 20)
    private(set) var complexityStatements = Self.defaultComplexityStatements

    private(set) var ignoresCaseStatements = false {
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

    mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration),
            configurationArray.isNotEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            length = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], configDict.isNotEmpty {
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }
                switch (key, value) {
                case (.error, let intValue as Int):
                    length.error = intValue
                case (.warning, let intValue as Int):
                    length.warning = intValue
                case (.ignoresCaseStatements, let boolValue as Bool):
                    ignoresCaseStatements = boolValue
                default:
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }
            }
        } else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }
    }
}
