import SwiftLintFramework
import XCTest

class DisableAllTests: SwiftLintTestCase {
    /// Example violations. Could be replaced with other single violations.
    private let violatingPhrases = [
        Example("let r = 0"), // Violates identifier_name
        Example(#"let myString:String = """#), // Violates colon_whitespace
        Example("// TODO: Some todo") // Violates todo
    ]

    // MARK: Violating Phrase
    /// Tests whether example violating phrases trigger when not applying disable rule
    func testViolatingPhrase() {
        for violatingPhrase in violatingPhrases {
            XCTAssertEqual(
                violations(violatingPhrase.with(code: violatingPhrase.code + "\n")).count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable Base
    /// Tests whether swiftlint:disable all protects properly
    func testDisableAll() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase.with(code: "// swiftlint:disable all\n" + violatingPhrase.code)
            XCTAssertEqual(
                violations(protectedPhrase).count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable all unprotects properly
    func testEnableAll() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable all
                \(violatingPhrase.code)\n
                """)
            XCTAssertEqual(
                violations(unprotectedPhrase).count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable Previous
    /// Tests whether swiftlint:disable:previous all protects properly
    func testDisableAllPrevious() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase
                .with(code: """
                    \(violatingPhrase.code)
                    // swiftlint:disable:previous all\n
                    """)
            XCTAssertEqual(
                violations(protectedPhrase).count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable:previous all unprotects properly
    func testEnableAllPrevious() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(violatingPhrase.code)
                // swiftlint:enable:previous all\n
                """)
            XCTAssertEqual(
                violations(unprotectedPhrase).count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable Next
    /// Tests whether swiftlint:disable:next all protects properly
    func testDisableAllNext() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase.with(code: "// swiftlint:disable:next all\n" + violatingPhrase.code)
            XCTAssertEqual(
                violations(protectedPhrase).count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    func testEnableAllNext() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable:next all
                \(violatingPhrase.code)\n
                """)
            XCTAssertEqual(
                violations(unprotectedPhrase).count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable This
    /// Tests whether swiftlint:disable:this all protects properly
    func testDisableAllThis() {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
            let protectedPhrase = violatingPhrase.with(code: rawViolatingPhrase + "// swiftlint:disable:this all\n")
            XCTAssertEqual(
                violations(protectedPhrase).count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    func testEnableAllThis() {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(rawViolatingPhrase)// swiftlint:enable:this all\n"
                """)
            XCTAssertEqual(
                violations(unprotectedPhrase).count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }
}
