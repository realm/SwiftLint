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
            "private let kFoo = 20.0",
            "public let kFoo = false",
            "internal let kFoo = \"Foo\"",
            "let kFoo = true",
            "struct Foo {\n" +
            "   let bar = 20.0\n" +
            "}",
            "private var foo = 20.0",
            "public var foo = false",
            "internal var foo = \"Foo\"",
            "var foo = true",
            "var foo = true, bar = true",
            "var foo = true, let kFoo = true",
            "let\n" +
            "   kFoo = true",
            "var foo: Int {\n" +
            "   return a + b\n" +
            "}",
            "let kFoo = {\n" +
            "   return a + b\n" +
            "}()"
        ],
        triggeringExamples: [
            "private let ↓Foo = 20.0",
            "public let ↓Foo = false",
            "internal let ↓Foo = \"Foo\"",
            "let ↓Foo = true",
            "let ↓foo = 2, ↓bar = true",
            "var foo = true, let ↓Foo = true",
            "let\n" +
            "    ↓foo = true",
            "let ↓foo = {\n" +
            "   return a + b\n" +
            "}()"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        if configuration.onlyPrivateMembers,
            let acl = dictionary.accessibility.flatMap(AccessControlLevel.init(identifier:)), !acl.isPrivate {
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
