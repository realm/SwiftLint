import SwiftLintCore

// swiftlint:disable:next blanket_disable_command
// swiftlint:disable let_var_whitespace

@AutoApply
struct DiscouragedDirectInitConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = DiscouragedDirectInitRule

    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    @ConfigurationElement(
        key: "types",
        postprocessor: { $0.formUnion($0.map { name in "\(name).init" }) }
    )
    private(set) var discouragedInits: Set = [
        "Bundle",
        "NSError",
        "UIDevice"
    ]
}
