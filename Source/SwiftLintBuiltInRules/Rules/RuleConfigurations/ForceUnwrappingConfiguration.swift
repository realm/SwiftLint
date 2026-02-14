import SwiftLintCore

@AutoConfigParser
struct ForceUnwrappingConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(
        key: "static_string_argument_functions",
        postprocessor: {
            $0.formUnion([
                "URL(string:)",
                "NSURL(string:)",
                "UIImage(named:)",
                "NSImage(named:)",
                "Data(hexString:)",
            ])
        }
    )
    private(set) var staticStringArgumentFunctions = Set<String>()
}
