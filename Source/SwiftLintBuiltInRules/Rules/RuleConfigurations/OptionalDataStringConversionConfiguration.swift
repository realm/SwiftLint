import SwiftLintCore

@AutoConfigParser
struct OptionalDataStringConversionConfiguration: SeverityBasedRuleConfiguration { // swiftlint:disable:this type_name
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning

    // When true, also flag leading-dot `.init(decoding:as:)` without explicit `String` type annotation.
    @ConfigurationElement(key: "include_implicit_init")
    private(set) var includeImplicitInit = false

    // TODO: [05/27/2027] Remove option after ~1 year.
    @ConfigurationElement(
        key: "allow_implicit_init",
        deprecationNotice: .suggestAlternative(ruleID: Parent.identifier, name: "include_implicit_init")
    )
    private(set) var allowImplicitInit = false
}
