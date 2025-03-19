/// Macro that lets an enum with a ``String`` raw type automatically conform to ``AcceptableByConfigurationElement``.
@attached(
    extension,
    conformances: AcceptableByConfigurationElement,
    names: named(init(fromAny:context:)), named(asOption)
)
public macro AcceptableByConfigurationElement() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AcceptableByConfigurationElement"
)

/// Deprecated. Use `AcceptableByConfigurationElement` instead.
@available(*, deprecated, renamed: "AcceptableByConfigurationElement")
@attached(
    extension,
    conformances: AcceptableByConfigurationElement,
    names: named(init(fromAny:context:)), named(asOption)
)
public macro MakeAcceptableByConfigurationElement() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AcceptableByConfigurationElement"
)
