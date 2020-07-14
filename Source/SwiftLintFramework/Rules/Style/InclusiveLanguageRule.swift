import SourceKittenFramework

public struct InclusiveLanguageRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = InclusiveLanguageConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "inclusive_language",
        name: "Inclusive Language",
        description: "Identifiers should use inclusive language that avoids"
            + " discrimination against groups of people based on race, gender, or socioeconomic status",
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

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind != .varParameter, // Will be caught by function declaration
            let name = dictionary.name,
            let nameByteRange = dictionary.nameByteRange
            else { return [] }

        let lowercased = name.lowercased()
        guard let term = configuration.denyList.first(where: { lowercased.contains($0) })
            else { return [] }

        let reason = "Declaration \(name) contains the term \"\(term)\" which is not considered inclusive."
        let violation = StyleViolation(
            ruleDescription: Swift.type(of: self).description,
            severity: configuration.severity,
            location: Location(file: file, byteOffset: nameByteRange.location),
            reason: reason
        )
        return [violation]
    }
}
