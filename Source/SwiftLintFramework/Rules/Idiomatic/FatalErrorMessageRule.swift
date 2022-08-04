import SourceKittenFramework

public struct FatalErrorMessageRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fatal_error_message",
        name: "Fatal Error Message",
        description: "A fatalError call should have a message.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            func foo() {
              fatalError("Foo")
            }
            """),
            Example("""
            func foo() {
              fatalError(x)
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            func foo() {
              ↓fatalError("")
            }
            """),
            Example("""
            func foo() {
              ↓fatalError()
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call,
            let offset = dictionary.offset,
            dictionary.name == "fatalError",
            hasEmptyBody(dictionary: dictionary, file: file) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func hasEmptyBody(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let bodyRange = dictionary.bodyByteRange else {
            return false
        }

        if bodyRange.length == 0 {
            return true
        }

        let body = file.stringView.substringWithByteRange(bodyRange)
        return body == "\"\""
    }
}
