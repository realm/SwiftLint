import SourceKittenFramework
import SwiftLintCore

@AutoApply
struct CyclomaticComplexityConfiguration: RuleConfiguration {
    typealias Parent = CyclomaticComplexityRule

    @ConfigurationElement(inline: true)
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 10, error: 20)
    @ConfigurationElement(key: "ignores_case_statements")
    private(set) var ignoresCaseStatements = false

    var params: [RuleParameter<Int>] {
        return length.params
    }
}
