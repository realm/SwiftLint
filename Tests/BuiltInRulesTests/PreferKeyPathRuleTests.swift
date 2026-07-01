import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct PreferKeyPathRuleTests {
    private static let extendedMode = ["restrict_to_standard_functions": false]
    private static let ignoreIdentity = ["ignore_identity_closures": true]
    private static let extendedModeAndIgnoreIdentity = [
        "restrict_to_standard_functions": false,
        "ignore_identity_closures": true,
    ]

    @Test(.disabled(if: SwiftVersion.current < .six))
    func identityExpressionInSwift6() {
        let description = PreferKeyPathRule.description
            .with(nonTriggeringExamples: #examples([
                "f.filter { a in b }",
                "f.g { $1 }".configuration(Self.extendedMode),
                "f { $0 }".configuration(Self.extendedModeAndIgnoreIdentity),
                "f.map { $0 }".configuration(Self.ignoreIdentity),
            ]))
            .with(triggeringExamples: #examples([
                "f.compactMap ↓{ $0 }",
                "f.map ↓{ a in a }",
                "f.g { $0 }".configuration(Self.extendedMode),
            ]))
            .with(corrections: #corrections([
                "f.map ↓{ $0 }":
                    "f.map(\\.self)",
                "f.g { $0 }".configuration(Self.extendedMode):
                    "f.g(\\.self)",
                "f { $0 }".configuration(Self.extendedModeAndIgnoreIdentity): // no change with option enabled
                    "f { $0 }",
                "f.map { $0 }".configuration(Self.ignoreIdentity): // no change with option enabled
                    "f.map { $0 }",
            ]))

        verifyRule(description)
    }
}
