import SwiftLintCore

@AutoConfigParser
struct AttributesConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = AttributesRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "attributes_with_arguments_always_on_line_above")
    private(set) var attributesWithArgumentsAlwaysOnNewLine = true
    @ConfigurationElement(key: "always_on_same_line")
    private(set) var alwaysOnSameLine = Set<String>(["@IBAction", "@NSManaged"])
    @ConfigurationElement(key: "always_on_line_above")
    private(set) var alwaysOnNewLine = Set<String>()
}
