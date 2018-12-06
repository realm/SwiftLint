import SourceKittenFramework

public struct XCTFailMessageRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "xctfail_message",
        name: "XCTFail Message",
        description: "An XCTFail call should include a description of the assertion.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            func testFoo() {
              XCTFail("bar")
            }
            """,
            """
            func testFoo() {
              XCTFail(bar)
            }
            """
        ],
        triggeringExamples: [
            """
            func testFoo() {
              ↓XCTFail()
            }
            """,
            """
            func testFoo() {
              ↓XCTFail("")
            }
            """
        ]
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.offset,
            dictionary.name == "XCTFail",
            hasEmptyMessage(dictionary: dictionary, file: file)
            else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }

    private func hasEmptyMessage(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength else { return false }

        guard bodyLength > 0 else { return true }

        let body = file.contents.bridge().substringWithByteRange(start: bodyOffset, length: bodyLength)
        return body == "\"\""
    }
}
