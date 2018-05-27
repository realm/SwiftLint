import Foundation
@testable import SwiftLintFramework
import XCTest

class DisableAllTests: XCTestCase {
    /// Example violations. Could be replaced with other single violations.
    private let violatingPhrases = [
        "let r = 0\n", // Violates identifier_name
        "let myString:String = \"\"\n", // Violates colon_whitespace
        "// TODO: Some todo\n" // Violates todo
    ]

    // MARK: Violating Phrase
    /// Tests whether example violating phrases trigger when not applying disable rule
    func testViolatingPhrase() {
        for violatingPhrase in violatingPhrases {
            XCTAssertEqual(violations(violatingPhrase).count, 1)
        }
    }

    // MARK: Enable / Disable Base
    /// Tests whether swiftlint:disable all protects properly
    func testDisableAll() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = "// swiftlint:disable all\n" + violatingPhrase
            XCTAssertEqual(violations(protectedPhrase).count, 0)
        }
    }

    /// Tests whether swiftlint:enable all unprotects properly
    func testEnableAll() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase =
                "// swiftlint:disable all\n" +
                violatingPhrase +
                "// swiftlint:enable all\n" +
                violatingPhrase
            XCTAssertEqual(violations(unprotectedPhrase).count, 1)
        }
    }

    // MARK: Enable / Disable Previous
    /// Tests whether swiftlint:disable:previous all protects properly
    func testDisableAllPrevious() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = violatingPhrase + "// swiftlint:disable:previous all\n"
            XCTAssertEqual(violations(protectedPhrase).count, 0)
        }
    }

    /// Tests whether swiftlint:enable:previous all unprotects properly
    func testEnableAllPrevious() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase =
                "// swiftlint:disable all\n" +
                violatingPhrase +
                violatingPhrase +
                "// swiftlint:enable:previous all\n"
            XCTAssertEqual(violations(unprotectedPhrase).count, 1)
        }
    }

    // MARK: Enable / Disable Next
    /// Tests whether swiftlint:disable:next all protects properly
    func testDisableAllNext() {
        for violatingPhrase in violatingPhrases {
            let protectedPhrase = "// swiftlint:disable:next all\n" + violatingPhrase
            XCTAssertEqual(violations(protectedPhrase).count, 0)
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    func testEnableAllNext() {
        for violatingPhrase in violatingPhrases {
            let unprotectedPhrase =
                "// swiftlint:disable all\n" +
                violatingPhrase +
                "// swiftlint:enable:next all\n" +
                violatingPhrase
            XCTAssertEqual(violations(unprotectedPhrase).count, 1)
        }
    }

    // MARK: Enable / Disable This
    /// Tests whether swiftlint:disable:this all protects properly
    func testDisableAllThis() {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.replacingOccurrences(of: "\n", with: "")
            let protectedPhrase = rawViolatingPhrase + "// swiftlint:disable:this all\n"
            XCTAssertEqual(violations(protectedPhrase).count, 0)
        }
    }

    /// Tests whether swiftlint:enable:next all unprotects properly
    func testEnableAllThis() {
        for violatingPhrase in violatingPhrases {
            let rawViolatingPhrase = violatingPhrase.replacingOccurrences(of: "\n", with: "")
            let unprotectedPhrase =
                "// swiftlint:disable all\n" +
                violatingPhrase +
                rawViolatingPhrase +
                "// swiftlint:enable:this all\n"
            XCTAssertEqual(violations(unprotectedPhrase).count, 1)
        }
    }
}
