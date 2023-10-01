/// Macro to be attached to rule configurations. It generates the configuration parsing logic
/// automatically based on the defined `@ConfigurationElement`s.
@attached(member, names: named(apply))
public macro AutoApply() = #externalMacro(
    module: "RuleConfigurationMacros",
    type: "AutoApply")

/// Macro that let's an enum with a ``String`` raw type automatically conform to ``AcceptableByConfigurationElement``.
@attached(extension, conformances: AcceptableByConfigurationElement, names: named(init), named(asOption))
public macro MakeAcceptableByConfigurationElement() = #externalMacro(
    module: "RuleConfigurationMacros",
    type: "MakeAcceptableByConfigurationElement")
