import SwiftLintCore

struct AttributesConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = AttributesRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "attributes_with_arguments_always_on_line_above")
    private(set) var attributesWithArgumentsAlwaysOnNewLine = true
    @ConfigurationElement(key: "always_on_same_line")
    private(set) var alwaysOnSameLine = Set<String>(["@IBAction", "@NSManaged"])
    @ConfigurationElement(key: "always_on_line_above")
    private(set) var alwaysOnNewLine = Set<String>()

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let attributesWithArgumentsAlwaysOnNewLine
                = configuration[$attributesWithArgumentsAlwaysOnNewLine] as? Bool {
            self.attributesWithArgumentsAlwaysOnNewLine = attributesWithArgumentsAlwaysOnNewLine
        }

        if let alwaysOnSameLine = configuration[$alwaysOnSameLine] as? [String] {
            self.alwaysOnSameLine = Set(alwaysOnSameLine)
        }

        if let alwaysOnNewLine = configuration[$alwaysOnNewLine] as? [String] {
            self.alwaysOnNewLine = Set(alwaysOnNewLine)
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
