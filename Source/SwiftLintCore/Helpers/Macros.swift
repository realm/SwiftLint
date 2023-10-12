/// Macro to be attached to rule configurations. It generates the configuration parsing logic
/// automatically based on the defined `@ConfigurationElement`s.
@attached(member, names: named(apply))
public macro AutoApply() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AutoApply"
)

/// Macro that lets an enum with a ``String`` raw type automatically conform to ``AcceptableByConfigurationElement``.
@attached(extension, conformances: AcceptableByConfigurationElement, names: named(init), named(asOption))
public macro MakeAcceptableByConfigurationElement() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "MakeAcceptableByConfigurationElement"
)

/// Macro that adds a conformance to the `SwiftSyntaxRule` protocol and a default `makeVisitor(file:)` implementation
/// that creates a visitor defined in the same file. It also adds an implementation of `preprocess(file:)` which folds
/// expressions if the `foldExpressions` argument is set.
@attached(extension, conformances: SwiftSyntaxRule, names: named(makeVisitor(file:)), named(preprocess(file:)))
public macro SwiftSyntaxRule(
    foldExpressions: Bool = false,
    needsLocationConverter: Bool = false,
    needsConfiguration: Bool = false
) = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "SwiftSyntaxRule"
)
