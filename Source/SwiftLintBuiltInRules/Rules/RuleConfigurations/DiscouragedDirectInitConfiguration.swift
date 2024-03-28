import SwiftLintCore

@AutoApply
struct DiscouragedDirectInitConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = DiscouragedDirectInitRule

    @ConfigurationElement(key: "severity")
    var severity = SeverityConfiguration<Parent>(.warning)

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
