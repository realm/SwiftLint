import SourceKittenFramework

public struct RacistDeclarationRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "racist_declaration",
        name: "Racist Declaration",
        description: "Terms that have racist connotations should not be used in declarations.",
        kind: .style,
        nonTriggeringExamples: [
            Example("let foo = \"abc\""),
            Example("""
            enum AllowList {
                case foo, bar
            }
            """),
            Example("func updateAllowList(add: String) {}")
        ],
        triggeringExamples: [
            Example("let ↓slave = \"abc\""),
            Example("""
            enum ↓BlackList {
                case foo, bar
            }
            """),
            Example("func ↓updateWhiteList(add: String) {}"),
            Example("""
            enum ListType {
                case ↓whitelist
                case ↓blacklist
            }
            """),
            Example("↓init(master: String, slave: String) {}"),
            Example("""
            final class FooBar {
                func register<↓Master, ↓Slave>(one: Master, two: Slave) {}
            }
            """)
        ]
    )

    private let racistTerms: Set<String> = [
        "whitelist",
        "blacklist",
        "master",
        "slave"
    ]

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind != .varParameter, // Will be caught by function declaration
            let name = dictionary.name,
            let nameByteRange = dictionary.nameByteRange
            else { return [] }

        let lowercased = name.lowercased()
        guard let term = racistTerms.first(where: { lowercased.contains($0) })
            else { return [] }

        let reason = "Declaration \(name) contains the term \"\(term)\" which has racist connotations."
        let violation = StyleViolation(
            ruleDescription: Swift.type(of: self).description,
            location: Location(file: file, byteOffset: nameByteRange.location),
            reason: reason
        )
        return [violation]
    }
}
