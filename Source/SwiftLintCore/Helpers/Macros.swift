/// Macro to be attached to rule configurations. It generates the configuration parsing logic
/// automatically based on the defined `@ConfigurationElement`s.
@attached(
    member,
    names: named(apply)
)
public macro AutoApply() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AutoApply"
)

/// Macro that lets an enum with a ``String`` raw type automatically conform to ``AcceptableByConfigurationElement``.
@attached(
    extension,
    conformances: AcceptableByConfigurationElement,
    names: named(init(fromAny:context:)), named(asOption)
)
public macro MakeAcceptableByConfigurationElement() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "MakeAcceptableByConfigurationElement"
)

/// Macro that adds a conformance to the ``SwiftSyntaxRule`` protocol and a default `makeVisitor(file:)` implementation
/// that creates a visitor defined in the rule struct.
///
/// - Parameters:
///   - foldExpressions: Setting it to `true` adds an implementation of `preprocess(file:)` which folds expressions
///                      before they are passed to the visitor.
///   - explicitRewriter: Set it to `true` to add a `makeRewriter(file:)` implementation which creates a rewriter
///                       defined in the rule struct. In this case, the rule automatically conforms to 
///                       ``SwiftSyntaxCorrectableRule``.
@attached(
    extension,
    conformances: SwiftSyntaxRule, SwiftSyntaxCorrectableRule,
    names: named(makeVisitor(file:)), named(preprocess(file:)), named(makeRewriter(file:))
)
public macro SwiftSyntaxRule(foldExpressions: Bool = false, explicitRewriter: Bool = false) = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "SwiftSyntaxRule"
)
