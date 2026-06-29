/// Macro to be attached to rule configurations. It generates the configuration parsing logic
/// automatically based on the defined `@ConfigurationElement`s.
@attached(
    member,
    names: named(apply), named(Parent)
)
public macro AutoConfigParser() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AutoConfigParser"
)

/// Deprecated. Use `AutoConfigParser` instead.
@available(*, deprecated, renamed: "AutoConfigParser")
@attached(
    member,
    names: named(apply), named(Parent)
)
public macro AutoApply() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "AutoConfigParser"
)

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

@attached(
    extension,
    names: named(notifyRuleDisabledOnce), named(postMessage)
)
public macro DisabledWithoutSourceKit() = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "DisabledWithoutSourceKit"
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

/// Macro that adds a conformance to the ``SwiftSyntaxRule`` protocol and a default `makeVisitor(file:)` implementation
/// that creates a visitor defined in the rule struct.
///
/// - Parameters:
///   - foldExpressions: Setting it to `true` adds an implementation of `preprocess(file:)` which folds expressions
///                      before they are passed to the visitor.
///   - explicitRewriter: Set it to `true` to add a `makeRewriter(file:)` implementation which creates a rewriter
///                       defined in the rule struct. In this case, the rule automatically conforms to
///                       ``SwiftSyntaxCorrectableRule``.
///   - correctable: Set it to `true` to make the rule conform to ``SwiftSyntaxCorrectableRule`` without an explicit
///                  rewriter.
///   - optIn: Set it to `true` to make the rule conform to ``OptInRule``.
@attached(
    extension,
    conformances: SwiftSyntaxRule, SwiftSyntaxCorrectableRule, OptInRule, Rule,
    names: named(makeVisitor(file:)), named(preprocess(file:)), named(makeRewriter(file:))
)
public macro SwiftSyntaxRule(foldExpressions: Bool = false,
                             explicitRewriter: Bool = false,
                             correctable: Bool = false,
                             optIn: Bool = false) = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "SwiftSyntaxRule"
)

/// Macro that allows to define an example for a rule. It generates an ``Example`` instance with the provided code,
/// configuration and other options. Valuable is that the code passed as the example's body is compiled, thus making
/// sure that the example is valid Swift code.
///
/// - Parameters:
///   - configuration: The untyped configuration to apply to the rule, if deviating from the default configuration.
///   - testMultiByteOffsets: Whether the example should be tested by prepending multi-byte grapheme clusters.
///   - testWrappingInComment: Whether test shall verify that the example wrapped in a comment doesn't trigger.
///   - testWrappingInString: Whether tests shall verify that the example wrapped into a string doesn't trigger.
///   - testDisableCommand: Whether tests shall verify that the disabled rule (comment in the example) doesn't trigger.
///   - testOnLinux: Whether the example should be tested on Linux.
///   - testOnWindows: Whether the example should be tested on Windows.
///   - excludeFromDocumentation: Whether the example should be excluded from the rule's documentation.
///   - body: The body of the example, which is compiled to ensure that it is valid Swift code.
@freestanding(expression)
public macro example(configuration: [String: any Sendable]? = nil,
                     testMultiByteOffsets: Bool = true,
                     testWrappingInComment: Bool = true,
                     testWrappingInString: Bool = true,
                     testDisableCommand: Bool = true,
                     testOnLinux: Bool = true,
                     testOnWindows: Bool = true,
                     excludeFromDocumentation: Bool = false,
                     body: () -> Void) -> Example = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "Example"
)
