import SourceKittenFramework

public struct LegacyHashingRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_hashing",
        name: "Legacy Hashing",
        description: "Prefer using the `hash(into:)` function instead of overriding `hashValue`",
        kind: .idiomatic,
        minSwiftVersion: .fourDotTwo,
        nonTriggeringExamples: [
            """
            struct Foo: Hashable {
              let bar: Int = 10

              func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
              }
            }
            """,
            """
            class Foo: Hashable {
              let bar: Int = 10

              func hash(into hasher: inout Hasher) {
                hasher.combine(bar)
              }
            }
            """,
            """
            var hashValue: Int { return 1 }
            class Foo: Hashable { \n }
            """,
            """
            class Foo: Hashable {
              let bar: String = "Foo"

              public var hashValue: String {
                return bar
              }
            }
            """,
            """
            class Foo: Hashable {
              let bar: String = "Foo"

              public var hashValue: String {
                get { return bar }
                set { bar = newValue }
              }
            }
            """
        ],
        triggeringExamples: [
            """
            struct Foo: Hashable {
                let bar: Int = 10

                public ↓var hashValue: Int {
                    return bar
                }
            }
            """,
            """
            class Foo: Hashable {
                let bar: Int = 10

                public ↓var hashValue: Int {
                    return bar
                }
            }
            """
        ]
    )

    // MARK: - ASTRule

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .varInstance,
            dictionary.setterAccessibility == nil,
            dictionary.typeName == "Int",
            dictionary.name == "hashValue",
            let offset = dictionary.offset else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
