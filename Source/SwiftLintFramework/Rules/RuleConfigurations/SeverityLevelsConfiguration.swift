public struct SeverityLevelsConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        let errorString: String
        if let errorValue = error {
            errorString = ", error: \(errorValue)"
        } else {
            errorString = ""
        }
        return "warning: \(warning)" + errorString
    }

    public var shortConsoleDescription: String {
        if let errorValue = error {
            return "w/e: \(warning)/\(errorValue)"
        }
        return "w: \(warning)"
    }

    var warning: Int
    var error: Int?

    var params: [RuleParameter<Int>] {
        if let error {
            return [RuleParameter(severity: .error, value: error),
                    RuleParameter(severity: .warning, value: warning)]
        }
        return [RuleParameter(severity: .warning, value: warning)]
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration), configurationArray.isNotEmpty {
            warning = configurationArray[0]
            error = (configurationArray.count > 1) ? configurationArray[1] : nil
        } else if let configDict = configuration as? [String: Int?],
            configDict.isNotEmpty, Set(configDict.keys).isSubset(of: ["warning", "error"]) {
            warning = (configDict["warning"] as? Int) ?? warning
            error = configDict["error"] as? Int
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}
