import SourceKittenFramework

public struct PrefixedTopLevelConstantRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = PrefixedConstantRuleConfiguration(onlyPrivateMembers: false)

    private let topLevelPrefix = "k"

    public init() {}

    public static let description = RuleDescription(
        identifier: "prefixed_toplevel_constant",
        name: "Prefixed Top-Level Constant",
        description: "Top-level constants should be prefixed by `k`.",
        kind: .style,
        nonTriggeringExamples: [
            Example("private let kFoo = 20.0"),
            Example("public let kFoo = false"),
            Example("internal let kFoo = \"Foo\""),
            Example("let kFoo = true"),
            Example("struct Foo {\n" +
            "   let bar = 20.0\n" +
            "}"),
            Example("private var foo = 20.0"),
            Example("public var foo = false"),
            Example("internal var foo = \"Foo\""),
            Example("var foo = true"),
            Example("var foo = true, bar = true"),
            Example("var foo = true, let kFoo = true"),
            Example("let\n" +
            "   kFoo = true"),
            Example("var foo: Int {\n" +
            "   return a + b\n" +
            "}"),
            Example("let kFoo = {\n" +
            "   return a + b\n" +
            "}()")
        ],
        triggeringExamples: [
            Example("private let ↓Foo = 20.0"),
            Example("public let ↓Foo = false"),
            Example("internal let ↓Foo = \"Foo\""),
            Example("let ↓Foo = true"),
            Example("let ↓foo = 2, ↓bar = true"),
            Example("var foo = true, let ↓Foo = true"),
            Example("let\n" +
            "    ↓foo = true"),
            Example("let ↓foo = {\n" +
            "   return a + b\n" +
            "}()")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        if configuration.onlyPrivateMembers,
            let acl = dictionary.accessibility, !acl.isPrivate {
            return []
        }

        guard
            kind == .varGlobal,
            dictionary.setterAccessibility == nil,
            dictionary.bodyLength == nil,
            dictionary.name?.hasPrefix(topLevelPrefix) == false,
            let nameOffset = dictionary.nameOffset
            else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: nameOffset))
        ]
    }
}
