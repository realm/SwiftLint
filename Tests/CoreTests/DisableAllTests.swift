import SwiftLintCore
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct DisableAllTests {
    /// Example violations. Could be replaced with other single violations.
    private static let violatingPhrases = [
        Example("let r = 0"),  // Violates identifier_name
        Example(#"let myString:String = """#),  // Violates colon_whitespace
        Example("// TODO: Some todo"),  // Violates todo
    ]

    // MARK: Violating Phrase
    /// Tests whether example violating phrases trigger when not applying disable rule
    @Test(arguments: violatingPhrases)
    func violatingPhrase(_ violatingPhrase: Example) {
        #expect(violations(violatingPhrase.with(code: violatingPhrase.code + "\n")).count == 1)
    }

    // MARK: Enable / Disable Base
    /// Tests whether swiftlint:disable all protects properly
    @Test(arguments: violatingPhrases)
    func disableAll(_ violatingPhrase: Example) {
        let code = "// swiftlint:disable all\n" + violatingPhrase.code + "\n// swiftlint:enable all\n"
        let protectedPhrase = violatingPhrase.with(code: code)
        #expect(violations(protectedPhrase).isEmpty)
    }

    /// Tests whether swiftlint:enable all unprotects properly
    @Test(arguments: violatingPhrases)
    func enableAll(_ violatingPhrase: Example) {
        let unprotectedPhrase = violatingPhrase.with(
            code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable all
                \(violatingPhrase.code)\n
                """)
        #expect(violations(unprotectedPhrase).count == 1)
    }

    // MARK: Enable / Disable Previous
    /// Tests whether swiftlint:disable:previous all protects properly
    @Test(arguments: violatingPhrases)
    func disableAllPrevious(_ violatingPhrase: Example) {
        let protectedPhrase =
            violatingPhrase
            .with(
                code: """
                    \(violatingPhrase.code)
                    // swiftlint:disable:previous all\n
                    """)
        #expect(violations(protectedPhrase).isEmpty)
    }

    /// Tests whether swiftlint:enable:previous all unprotects properly
    @Test(arguments: violatingPhrases)
    func enableAllPrevious(_ violatingPhrase: Example) {
        let unprotectedPhrase = violatingPhrase.with(
            code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(violatingPhrase.code)
                // swiftlint:enable:previous all
                // swiftlint:enable all
                """)
        #expect(violations(unprotectedPhrase).count == 1)
    }

    // MARK: Enable / Disable Next
    /// Tests whether swiftlint:disable:next all protects properly
    @Test(arguments: violatingPhrases)
    func disableAllNext(_ violatingPhrase: Example) {
        let protectedPhrase = violatingPhrase.with(code: "// swiftlint:disable:next all\n" + violatingPhrase.code)
        #expect(violations(protectedPhrase).isEmpty)
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    @Test(arguments: violatingPhrases)
    func enableAllNext(_ violatingPhrase: Example) {
        let unprotectedPhrase = violatingPhrase.with(
            code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable:next all
                \(violatingPhrase.code)
                // swiftlint:enable all
                """)
        #expect(violations(unprotectedPhrase).count == 1)
    }

    // MARK: Enable / Disable This
    /// Tests whether swiftlint:disable:this all protects properly
    @Test(arguments: violatingPhrases)
    func disableAllThis(_ violatingPhrase: Example) {
        let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
        let protectedPhrase = violatingPhrase.with(code: rawViolatingPhrase + "// swiftlint:disable:this all\n")
        #expect(violations(protectedPhrase).isEmpty)
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    @Test(arguments: violatingPhrases)
    func enableAllThis(_ violatingPhrase: Example) {
        let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
        let unprotectedPhrase = violatingPhrase.with(
            code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(rawViolatingPhrase)// swiftlint:enable:this all
                // swiftlint:enable all
                """)
        #expect(violations(unprotectedPhrase).count == 1)
    }
}
