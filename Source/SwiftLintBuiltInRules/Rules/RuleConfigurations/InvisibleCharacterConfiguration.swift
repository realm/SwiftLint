import Foundation
import SwiftLintCore

@AutoConfigParser
struct InvisibleCharacterConfiguration: SeverityBasedRuleConfiguration {
    static let defaultCharacterDescriptions: [UnicodeScalar: String] = [
        "\u{200B}": "U+200B (zero-width space)",
        "\u{200C}": "U+200C (zero-width non-joiner)",
        "\u{FEFF}": "U+FEFF (zero-width no-break space)",
    ]

    private static let defaultCharacters = Set(defaultCharacterDescriptions.keys.map(\.hexCode))

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.error
    @ConfigurationElement(
        key: "include_hex_codes",
        postprocessor: { $0.formUnion(defaultCharacters) }
    )
    private(set) var violatingCharacters = Set<String>()

    func violatingScalars() -> Set<UnicodeScalar> {
        Set(violatingCharacters.compactMap { .init(hexCode: $0) })
    }
}

private extension UnicodeScalar {
    var hexCode: String {
        .init(value, radix: 16, uppercase: true)
    }

    init?(hexCode: String) {
        guard let value = UInt32(hexCode, radix: 16),
              let scalar = Self(value) else {
            return nil
        }
        self = scalar
    }
}
