import Foundation
import SourceKittenFramework

public struct EmptyStringRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_string",
        name: "Empty String",
        description: "Prefer checking `isEmpty` over comparing `string` to an empty string literal.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("myString.isEmpty"),
            Example("!myString.isEmpty"),
            Example("\"\"\"\nfoo==\n\"\"\"")
        ],
        triggeringExamples: [
            Example("myString↓ == \"\""),
            Example("myString↓ != \"\"")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "\\b\\s*(==|!=)\\s*\"\""
        return file.match(pattern: pattern, with: [.string]).compactMap { range in
            guard let byteRange = file.stringView.NSRangeToByteRange(NSRange(location: range.location, length: 1)),
                case let kinds = file.syntaxMap.kinds(inByteRange: byteRange),
                kinds.isEmpty else {
                    return nil
            }

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }
}
