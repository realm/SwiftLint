import SwiftLintCore

@AutoConfigParser
struct RedundantDiscardableLetConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantDiscardableLetRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_swiftui_view_bodies")
    private(set) var ignoreSwiftUIViewBodies = false
}
