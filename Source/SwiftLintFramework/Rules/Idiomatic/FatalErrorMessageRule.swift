import SourceKittenFramework

public struct FatalErrorMessageRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fatal_error_message",
        name: "Fatal Error Message",
        description: "A fatalError call should have a message.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            func foo() {
              fatalError("Foo")
            }
            """,
            """
            func foo() {
              fatalError(x)
            }
            """
        ],
        triggeringExamples: [
            """
            func foo() {
              ↓fatalError("")
            }
            """,
            """
            func foo() {
              ↓fatalError()
            }
            """
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call,
            let offset = dictionary.offset,
            dictionary.name == "fatalError",
            hasEmptyBody(dictionary: dictionary, file: file) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func hasEmptyBody(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength else {
                return false
        }

        if bodyLength == 0 {
            return true
        }

        let body = file.contents.bridge().substringWithByteRange(start: bodyOffset, length: bodyLength)
        return body == "\"\""
    }
}
