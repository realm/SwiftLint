import XCTest

final class OptionalDataStringConversionRuleTests: SwiftLintTestCase {
    func testWithDefaultConfiguration() {
        // This uses the examples embedded in OptionalDataStringConversionRule.description.
        // The rule's description includes both the original String(decoding:as:) case and
        // the added String.init(...) and leading-dot .init(...) examples.
        verifyRule(OptionalDataStringConversionRule.description)
    }
}
