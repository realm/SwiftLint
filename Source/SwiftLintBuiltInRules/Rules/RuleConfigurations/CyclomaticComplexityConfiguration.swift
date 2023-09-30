import SourceKittenFramework
import SwiftLintCore

@AutoApply
struct CyclomaticComplexityConfiguration: RuleConfiguration, Equatable {
    typealias Parent = CyclomaticComplexityRule

    private static let defaultComplexityStatements: Set<StatementKind> = [
        .forEach,
        .if,
        .guard,
        .for,
        .repeatWhile,
        .while
    ]

    @ConfigurationElement
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 10, error: 20)
    @ConfigurationElement(key: "ignores_case_statements")
    private(set) var ignoresCaseStatements = false

    var params: [RuleParameter<Int>] {
        return length.params
    }

    var complexityStatements: Set<StatementKind> {
        Self.defaultComplexityStatements.union(ignoresCaseStatements ? [] : [.case])
    }
}
