/// Macro to be added to rule configuration that generates the configuration parsing automatically
/// based on the defined `@ConfigurationElement`s.
@attached(member, names: named(apply))
public macro AutoApply() = #externalMacro(
    module: "RuleConfigurationMacros",
    type: "AutoApply")

/// Macro that let's an enum with a ``String`` raw type automatically conform to ``AcceptableByConfigurationElement``.
@attached(extension, conformances: AcceptableByConfigurationElement, names: named(apply), named(asOption))
public macro MakeAcceptableByConfigurationElement() = #externalMacro(
    module: "RuleConfigurationMacros",
    type: "MakeAcceptableByConfigurationElement")
