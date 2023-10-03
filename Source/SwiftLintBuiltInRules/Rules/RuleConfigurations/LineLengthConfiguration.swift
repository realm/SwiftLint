import SwiftLintCore

@AutoApply
struct LineLengthConfiguration: RuleConfiguration {
    typealias Parent = LineLengthRule

    @ConfigurationElement
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 120, error: 200)
    @ConfigurationElement(key: "ignores_urls")
    private(set) var ignoresURLs = false
    @ConfigurationElement(key: "ignores_function_declarations")
    private(set) var ignoresFunctionDeclarations = false
    @ConfigurationElement(key: "ignores_comments")
    private(set) var ignoresComments = false
    @ConfigurationElement(key: "ignores_interpolated_strings")
    private(set) var ignoresInterpolatedStrings = false

    var params: [RuleParameter<Int>] {
        return length.params
    }
}
