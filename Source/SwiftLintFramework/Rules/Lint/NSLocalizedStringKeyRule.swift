import Foundation
import SourceKittenFramework

public struct NSLocalizedStringKeyRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nslocalizedstring_key",
        name: "NSLocalizedString Key",
        description: "Static strings should be used as key in NSLocalizedString in order to genstrings work.",
        kind: .lint,
        nonTriggeringExamples: [
            "NSLocalizedString(\"key\", comment: nil)",
            "NSLocalizedString(\"key\" + \"2\", comment: nil)"
        ],
        triggeringExamples: [
            "NSLocalizedString(↓method(), comment: nil)",
            "NSLocalizedString(↓\"key_\\(param)\", comment: nil)"
        ]
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call,
            dictionary.name == "NSLocalizedString",
            let firstArgument = dictionary.enclosedArguments.first,
            firstArgument.name == nil,
            let offset = firstArgument.offset,
            let length = firstArgument.length,
            case let kinds = file.syntaxMap.kinds(inByteRange: NSRange(location: offset, length: length)),
            !kinds.allSatisfy({ $0 == .string }) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
