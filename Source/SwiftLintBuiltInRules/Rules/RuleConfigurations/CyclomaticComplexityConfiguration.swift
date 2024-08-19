import SourceKittenFramework
import SwiftLintCore

@AutoConfigParser
struct CyclomaticComplexityConfiguration: RuleConfiguration {
    typealias Parent = CyclomaticComplexityRule

    @ConfigurationElement(inline: true)
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 10, error: 20)
    @ConfigurationElement(key: "ignores_case_statements")
    private(set) var ignoresCaseStatements = false

    var params: [RuleParameter<Int>] {
        length.params
    }
}
