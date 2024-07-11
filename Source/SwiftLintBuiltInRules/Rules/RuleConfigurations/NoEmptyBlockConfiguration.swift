import SwiftLintCore

@AutoApply
struct NoEmptyBlockConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = NoEmptyBlockRule

    @MakeAcceptableByConfigurationElement
    enum CodeBlockType: String, CaseIterable {
        case accessorBodies = "accessor_bodies"
        case functionBodies = "function_bodies"
        case initializerBodies = "initializer_bodies"
        case statementBlocks = "statement_blocks"

        static let all = Set(allCases)
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    @ConfigurationElement(key: "disabled")
    private(set) var disabledBlockTypes: [CodeBlockType] = []

    var enabledBlockTypes: Set<CodeBlockType> {
        CodeBlockType.all.subtracting(disabledBlockTypes)
    }
}
