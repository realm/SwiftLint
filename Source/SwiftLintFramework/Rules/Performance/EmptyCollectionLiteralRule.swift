import SourceKittenFramework

public struct EmptyCollectionLiteralRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_collection_literal",
        name: "Empty Collection Literal",
        description: "Prefer checking `isEmpty` over comparing collection to an empty array or dictionary literal.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("myArray = []"),
            Example("myArray.isEmpty"),
            Example("!myArray.isEmpty"),
            Example("myDict = [:]")
        ],
        triggeringExamples: [
            Example("myArray↓ == []"),
            Example("myArray↓ != []"),
            Example("myArray↓ == [ ]"),
            Example("myDict↓ == [:]"),
            Example("myDict↓ != [:]"),
            Example("myDict↓ == [: ]"),
            Example("myDict↓ == [ :]"),
            Example("myDict↓ == [ : ]")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "\\b\\s*(==|!=)\\s*\\[\\s*:?\\s*\\]"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
