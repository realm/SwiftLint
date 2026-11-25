import SourceKittenFramework
import SwiftLintCore

@AutoConfigParser
struct CognitiveComplexityConfiguration: RuleConfiguration {
    typealias Parent = CognitiveComplexityRule

    @ConfigurationElement(inline: true)
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 15, error: 20)
    @ConfigurationElement(key: "ignores_logical_operator_sequences")
    private(set) var ignoresLogicalOperatorSequences = false

    var params: [RuleParameter<Int>] {
        length.params
    }
}
