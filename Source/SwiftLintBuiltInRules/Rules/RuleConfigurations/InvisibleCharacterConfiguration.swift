import SwiftLintCore

@AutoConfigParser
struct InvisibleCharacterConfiguration: SeverityBasedRuleConfiguration {
    static let defaultCharacterDescriptions: [UnicodeScalar: String] = [
        "\u{200B}": "U+200B (zero-width space)",
        "\u{200C}": "U+200C (zero-width non-joiner)",
        "\u{FEFF}": "U+FEFF (zero-width no-break space)",
    ]

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.error
    @ConfigurationElement(
        key: "additional_code_points",
        postprocessor: {
            $0.formUnion(defaultCharacterDescriptions.keys)
        }
    )
    private(set) var violatingCharacters = Set<UnicodeScalar>()
}

extension UnicodeScalar: AcceptableByConfigurationElement {
    public init(fromAny value: Any, context ruleID: String) throws(Issue) {
        guard let hexCode = value as? String,
              let codePoint = UInt32(hexCode, radix: 16),
              let scalar = Self(codePoint) else {
            throw .invalidConfiguration(
                ruleID: ruleID,
                message: "\(value) is not a valid Unicode scalar code point."
            )
        }
        self = scalar
    }

    public func asOption() -> OptionType {
        .string(.init(value, radix: 16, uppercase: true))
    }
}
