import SwiftLintCore

@AutoApply
struct UnusedDeclarationConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = UnusedDeclarationRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.error
    @ConfigurationElement(key: "include_public_and_open")
    private(set) var includePublicAndOpen = false
    @ConfigurationElement(key: "related_usrs_to_skip")
    private(set) var relatedUSRsToSkip = Set(["s:7SwiftUI15PreviewProviderP"])
}
