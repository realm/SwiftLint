import SwiftLintCore

@AutoConfigParser
struct OptionalDataStringConversionConfiguration: SeverityBasedRuleConfiguration { // swiftlint:disable:this type_name
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning

    // When true, also flag leading-dot `.init(decoding:as:)` without explicit `String` type annotation.
    // Default is false to preserve conservative behavior.
    @ConfigurationElement(key: "allow_implicit_init")
    private(set) var allowImplicitInit = false
}
