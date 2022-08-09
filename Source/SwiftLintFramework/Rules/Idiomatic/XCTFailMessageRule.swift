import SourceKittenFramework

public struct XCTFailMessageRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "xctfail_message",
        name: "XCTFail Message",
        description: "An XCTFail call should include a description of the assertion.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func testFoo() {
              XCTFail("bar")
            }
            """),
            Example("""
            func testFoo() {
              XCTFail(bar)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            func testFoo() {
              ↓XCTFail()
            }
            """),
            Example("""
            func testFoo() {
              ↓XCTFail("")
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.offset,
            dictionary.name == "XCTFail",
            hasEmptyMessage(dictionary: dictionary, file: file)
            else {
                return []
        }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }

    private func hasEmptyMessage(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let bodyRange = dictionary.bodyByteRange else {
            return false
        }

        guard bodyRange.length > 0 else { return true }

        let body = file.stringView.substringWithByteRange(bodyRange)
        return body == "\"\""
    }
}
