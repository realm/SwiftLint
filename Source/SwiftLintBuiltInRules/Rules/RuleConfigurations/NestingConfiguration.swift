import SwiftLintCore

@AutoApply
struct NestingConfiguration: RuleConfiguration {
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
