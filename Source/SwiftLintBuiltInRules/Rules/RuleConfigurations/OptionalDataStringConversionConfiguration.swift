import SwiftLintCore

@AutoConfigParser
struct OptionalDataStringConversionConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning

    // New option: when true, also flag leading-dot `.init(decoding:as:)` even without an explicit `String` type annotation
    // Default is false to preserve conservative behavior
    @ConfigurationElement(key: "allow_implicit_init")
    private(set) var allowImplicitInit: Bool = false
}
