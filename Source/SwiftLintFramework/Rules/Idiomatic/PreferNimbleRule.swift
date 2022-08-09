public struct PreferNimbleRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prefer_nimble",
        name: "Prefer Nimble",
        description: "Prefer Nimble matchers over XCTAssert functions.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("expect(foo) == 1"),
            Example("expect(foo).to(equal(1))")
        ],
        triggeringExamples: [
            Example("↓XCTAssertTrue(foo)"),
            Example("↓XCTAssertEqual(foo, 2)"),
            Example("↓XCTAssertNotEqual(foo, 2)"),
            Example("↓XCTAssertNil(foo)"),
            Example("↓XCTAssert(foo)"),
            Example("↓XCTAssertGreaterThan(foo, 10)")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call,
              let offset = dictionary.offset,
              let name = dictionary.name,
              name.starts(with: "XCTAssert") else {
            return []
        }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
