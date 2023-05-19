struct NestingConfiguration: RuleConfiguration, Equatable {
    typealias Parent = NestingRule
    typealias Severity = SeverityLevelsConfiguration<Parent>

    var consoleDescription: String {
        return "(type_level) \(typeLevel.shortConsoleDescription)"
            + ", (function_level) \(functionLevel.shortConsoleDescription)"
            + ", (check_nesting_in_closures_and_statements) \(checkNestingInClosuresAndStatements)"
            + ", (always_allow_one_type_in_functions) \(alwaysAllowOneTypeInFunctions)"
    }

    private(set) var typeLevel = Severity(warning: 1)
    private(set) var functionLevel = Severity(warning: 2)
    private(set) var checkNestingInClosuresAndStatements = true
    private(set) var alwaysAllowOneTypeInFunctions = false

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let typeLevelConfiguration = configurationDict["type_level"] {
            try typeLevel.apply(configuration: typeLevelConfiguration)
        }
        if let functionLevelConfiguration = configurationDict["function_level"] {
            try functionLevel.apply(configuration: functionLevelConfiguration)
        } else if let statementLevelConfiguration = configurationDict["statement_level"] {
            queuedPrintError(
                """
                warning: 'statement_level' has been renamed to 'function_level' and will be completely removed \
                in a future release.
                """
            )
            try functionLevel.apply(configuration: statementLevelConfiguration)
        }
        checkNestingInClosuresAndStatements =
            configurationDict["check_nesting_in_closures_and_statements"] as? Bool ?? true
        alwaysAllowOneTypeInFunctions =
            configurationDict["always_allow_one_type_in_functions"] as? Bool ?? false
    }

    func severity(with config: Severity, for level: Int) -> ViolationSeverity? {
        if let error = config.error, level > error {
            return .error
        } else if level > config.warning {
            return .warning
        }
        return nil
    }

    func threshold(with config: Severity, for severity: ViolationSeverity) -> Int {
        switch severity {
        case .error: return config.error ?? config.warning
        case .warning: return config.warning
        }
    }
}
