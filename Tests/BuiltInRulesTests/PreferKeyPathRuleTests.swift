@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class PreferKeyPathRuleTests: SwiftLintTestCase {
    private static let extendedMode = ["restrict_to_standard_functions": false]

    func testIdentityExpressionInSwift6() throws {
        try XCTSkipIf(SwiftVersion.current < .six)

        let description = PreferKeyPathRule.description
            .with(nonTriggeringExamples: [
                Example("f.filter { a in b }"),
                Example("f.g { $1 }", configuration: Self.extendedMode),
            ])
            .with(triggeringExamples: [
                Example("f.compactMap ↓{ $0 }"),
                Example("f.map ↓{ a in a }"),
                Example("f.g { $0 }", configuration: Self.extendedMode),
            ])
            .with(corrections: [
                Example("f.map ↓{ $0 }"):
                    Example("f.map(\\.self)"),
                Example("f.g { $0 }", configuration: Self.extendedMode):
                    Example("f.g(\\.self)"),
            ])

        verifyRule(description)
    }
}
