import SwiftLintFramework
import XCTest

class DisableAllTests: XCTestCase {
    /// Example violations. Could be replaced with other single violations.
    private let violatingPhrases = [
        Example("let r = 0"), // Violates identifier_name
        Example(#"let myString:String = """#), // Violates colon_whitespace
        Example("// TODO: Some todo") // Violates todo
    ]

    // MARK: Violating Phrase
    /// Tests whether example violating phrases trigger when not applying disable rule
    func testViolatingPhrase() async {
        for violatingPhrase in violatingPhrases {
            let count = await violations(violatingPhrase.with(code: violatingPhrase.code + "\n")).count
            XCTAssertEqual(
                count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable Base
    /// Tests whether swiftlint:disable all protects properly
    func testDisableAll() async {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase.with(code: "// swiftlint:disable all\n" + violatingPhrase.code)
            let count = await violations(protectedPhrase).count
            XCTAssertEqual(
                count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable all unprotects properly
    func testEnableAll() async {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable all
                \(violatingPhrase.code)\n
                """)
            let count = await violations(unprotectedPhrase).count
            XCTAssertEqual(
                count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable Previous
    /// Tests whether swiftlint:disable:previous all protects properly
    func testDisableAllPrevious() async {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase
                .with(code: """
                    \(violatingPhrase.code)
                    // swiftlint:disable:previous all\n
                    """)
            let count = await violations(protectedPhrase).count
            XCTAssertEqual(
                count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable:previous all unprotects properly
    func testEnableAllPrevious() async {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(violatingPhrase.code)
                // swiftlint:enable:previous all\n
                """)
            let count = await violations(unprotectedPhrase).count
            XCTAssertEqual(
                count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable Next
    /// Tests whether swiftlint:disable:next all protects properly
    func testDisableAllNext() async {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase.with(code: "// swiftlint:disable:next all\n" + violatingPhrase.code)
            let count = await violations(protectedPhrase).count
            XCTAssertEqual(
                count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    func testEnableAllNext() async {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                // swiftlint:enable:next all
                \(violatingPhrase.code)\n
                """)
            let count = await violations(unprotectedPhrase).count
            XCTAssertEqual(
                count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    // MARK: Enable / Disable This
    /// Tests whether swiftlint:disable:this all protects properly
    func testDisableAllThis() async {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
            let protectedPhrase = violatingPhrase.with(code: rawViolatingPhrase + "// swiftlint:disable:this all\n")
            let count = await violations(protectedPhrase).count
            XCTAssertEqual(
                count,
                0,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    func testEnableAllThis() async {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.code.replacingOccurrences(of: "\n", with: "")
            let unprotectedPhrase = violatingPhrase.with(code: """
                // swiftlint:disable all
                \(violatingPhrase.code)
                \(rawViolatingPhrase)// swiftlint:enable:this all\n"
                """)
            let count = await violations(unprotectedPhrase).count
            XCTAssertEqual(
                count,
                1,
                #function,
                file: violatingPhrase.file,
                line: violatingPhrase.line)
        }
    }
}
