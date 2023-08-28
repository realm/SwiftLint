import SwiftLintCore

struct NestingConfiguration: RuleConfiguration, Equatable {
    typealias Parent = NestingRule
    typealias Severity = SeverityLevelsConfiguration<Parent>

    @ConfigurationElement(key: "type_level")
    private(set) var typeLevel = Severity(warning: 1)
    @ConfigurationElement(key: "function_level")
    private(set) var functionLevel = Severity(warning: 2)
    @ConfigurationElement(key: "check_nesting_in_closures_and_statements")
    private(set) var checkNestingInClosuresAndStatements = true
    @ConfigurationElement(key: "always_allow_one_type_in_functions")
    private(set) var alwaysAllowOneTypeInFunctions = false

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let typeLevelConfiguration = configurationDict[$typeLevel] {
            try typeLevel.apply(configuration: typeLevelConfiguration)
        }
        if let functionLevelConfiguration = configurationDict[$functionLevel] {
            try functionLevel.apply(configuration: functionLevelConfiguration)
        }
        checkNestingInClosuresAndStatements =
            configurationDict[$checkNestingInClosuresAndStatements] as? Bool ?? true
        alwaysAllowOneTypeInFunctions =
            configurationDict[$alwaysAllowOneTypeInFunctions] as? Bool ?? false
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
