import SwiftLintCore

@AutoApply
struct UnusedDeclarationConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = UnusedDeclarationRule

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>.error
    @ConfigurationElement(key: "include_public_and_open")
    private(set) var includePublicAndOpen = false
    @ConfigurationElement(
        key: "related_usrs_to_skip",
        postprocessor: { $0.insert("s:7SwiftUI15PreviewProviderP") }
    )
    private(set) var relatedUSRsToSkip = Set<String>()
}
