import SwiftLintCore

@AutoConfigParser
struct LineLengthConfiguration: RuleConfiguration {
    typealias Parent = LineLengthRule

    @ConfigurationElement(inline: true)
    private(set) var length = SeverityLevelsConfiguration<Parent>(warning: 120, error: 200)
    @ConfigurationElement(key: "ignores_urls")
    private(set) var ignoresURLs = false
    @ConfigurationElement(key: "ignores_function_declarations")
    private(set) var ignoresFunctionDeclarations = false
    @ConfigurationElement(key: "ignores_comments")
    private(set) var ignoresComments = false
    @ConfigurationElement(key: "ignores_interpolated_strings")
    private(set) var ignoresInterpolatedStrings = false
    @ConfigurationElement(key: "excluded_lines_patterns")
    private(set) var excludedLinesPatterns: Set<String> = []

    var params: [RuleParameter<Int>] {
        length.params
    }
}
