import SwiftLintCore

@AutoConfigParser
struct NoEmptyBlockConfiguration: SeverityBasedRuleConfiguration {
    @AcceptableByConfigurationElement
    enum CodeBlockType: String, CaseIterable {
        case functionBodies = "function_bodies"
        case initializerBodies = "initializer_bodies"
        case statementBlocks = "statement_blocks"
        case closureBlocks = "closure_blocks"

        static let all = Set(allCases)
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    @ConfigurationElement(key: "disabled_block_types")
    private(set) var disabledBlockTypes: [CodeBlockType] = []

    @ConfigurationElement(key: "allow_compact_empty_blocks")
    private(set) var allowCompactEmptyBlocks = false

    var enabledBlockTypes: Set<CodeBlockType> {
        CodeBlockType.all.subtracting(disabledBlockTypes)
    }
}
