import SourceKittenFramework

public struct LegacyHashingRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_hashing",
        name: "Legacy Hashing",
        description: "Prefer using the `hash(into:)` function instead of overriding `hashValue`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            struct Foo: Hashable {
              let bar: Int = 10

              func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
              }
            }
            """),
            Example("""
            class Foo: Hashable {
              let bar: Int = 10

              func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
              }
            }
            """),
            Example("""
            var hashValue: Int { return 1 }
            class Foo: Hashable { \n }
            """),
            Example("""
            class Foo: Hashable {
              let bar: String = "Foo"

              public var hashValue: String {
                return bar
              }
            }
            """),
            Example("""
            class Foo: Hashable {
              let bar: String = "Foo"

              public var hashValue: String {
                get { return bar }
                set { bar = newValue }
              }
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            struct Foo: Hashable {
                let bar: Int = 10

                public ↓var hashValue: Int {
                    return bar
                }
            }
            """),
            Example("""
            class Foo: Hashable {
                let bar: Int = 10

                public ↓var hashValue: Int {
                    return bar
                }
            }
            """)
        ]
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .varInstance,
            dictionary.setterAccessibility == nil,
            dictionary.typeName == "Int",
            dictionary.name == "hashValue",
            let offset = dictionary.offset else {
                return []
        }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
