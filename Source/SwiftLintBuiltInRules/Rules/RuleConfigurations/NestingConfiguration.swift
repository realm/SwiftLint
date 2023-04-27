struct NestingConfiguration: RuleConfiguration, Equatable {
    var consoleDescription: String {
        return "(type_level) \(typeLevel.shortConsoleDescription)"
            + ", (function_level) \(functionLevel.shortConsoleDescription)"
            + ", (check_nesting_in_closures_and_statements) \(checkNestingInClosuresAndStatements)"
            + ", (always_allow_one_type_in_functions) \(alwaysAllowOneTypeInFunctions)"
    }

    var typeLevel: SeverityLevelsConfiguration
    var functionLevel: SeverityLevelsConfiguration
    var checkNestingInClosuresAndStatements: Bool
    var alwaysAllowOneTypeInFunctions: Bool

    init(typeLevelWarning: Int,
         typeLevelError: Int?,
         functionLevelWarning: Int,
         functionLevelError: Int?,
         checkNestingInClosuresAndStatements: Bool = true,
         alwaysAllowOneTypeInFunctions: Bool = false) {
        self.typeLevel = SeverityLevelsConfiguration(warning: typeLevelWarning, error: typeLevelError)
        self.functionLevel = SeverityLevelsConfiguration(warning: functionLevelWarning, error: functionLevelError)
        self.checkNestingInClosuresAndStatements = checkNestingInClosuresAndStatements
        self.alwaysAllowOneTypeInFunctions = alwaysAllowOneTypeInFunctions
    }

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let typeLevelConfiguration = configurationDict["type_level"] {
            try typeLevel.apply(configuration: typeLevelConfiguration)
        }
        if let functionLevelConfiguration = configurationDict["function_level"] {
            try functionLevel.apply(configuration: functionLevelConfiguration)
        } else if let statementLevelConfiguration = configurationDict["statement_level"] {
            queuedPrintError(
                """
                'statement_level' has been renamed to 'function_level' and will be completely removed in a future \
                release.
                """
            )
            try functionLevel.apply(configuration: statementLevelConfiguration)
        }
        checkNestingInClosuresAndStatements =
            configurationDict["check_nesting_in_closures_and_statements"] as? Bool ?? true
        alwaysAllowOneTypeInFunctions =
            configurationDict["always_allow_one_type_in_functions"] as? Bool ?? false
    }

    func severity(with config: SeverityLevelsConfiguration, for level: Int) -> ViolationSeverity? {
        if let error = config.error, level > error {
            return .error
        } else if level > config.warning {
            return .warning
        }
        return nil
    }

    func threshold(with config: SeverityLevelsConfiguration, for severity: ViolationSeverity) -> Int {
        switch severity {
        case .error: return config.error ?? config.warning
        case .warning: return config.warning
        }
    }
}
