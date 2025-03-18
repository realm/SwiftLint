/// Macro to be attached to rule configurations. It generates the configuration parsing logic
/// automatically based on the defined `@ConfigurationElement`s.
@attached(
    member,
    names: named(apply)
)
public macro AutoConfigParser() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AutoConfigParser"
)

/// Deprecated. Use `AutoConfigParser` instead.
@available(*, deprecated, renamed: "AutoConfigParser")
@attached(
    member,
    names: named(apply)
)
public macro AutoApply() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AutoConfigParser"
)
