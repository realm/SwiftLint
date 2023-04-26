import SwiftLintCore
import XCTest

class RegionTests: SwiftLintTestCase {
    // MARK: Regions From Files

    func testNoRegionsInEmptyFile() {
        let file = SwiftLintFile(contents: "")
        XCTAssertEqual(file.regions(), [])
    }

    func testNoRegionsInFileWithNoCommands() {
        let file = SwiftLintFile(contents: String(repeating: "\n", count: 100))
        XCTAssertEqual(file.regions(), [])
    }

    func testRegionsFromSingleCommand() {
        // disable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:disable rule_id\n")
            let start = Location(file: nil, line: 1, character: 29)
            let end = Location(file: nil, line: .max, character: .max)
            XCTAssertEqual(file.regions(), [Region(start: start, end: end, disabledRuleIdentifiers: ["rule_id"])])
        }
        // enable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:enable rule_id\n")
            let start = Location(file: nil, line: 1, character: 28)
            let end = Location(file: nil, line: .max, character: .max)
            XCTAssertEqual(file.regions(), [Region(start: start, end: end, disabledRuleIdentifiers: [])])
        }
    }

    func testRegionsFromMatchingPairCommands() {
        // disable/enable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:disable rule_id\n// swiftlint:enable rule_id\n")
            XCTAssertEqual(file.regions(), [
                Region(start: Location(file: nil, line: 1, character: 29),
                       end: Location(file: nil, line: 2, character: 27),
                       disabledRuleIdentifiers: ["rule_id"]),
                Region(start: Location(file: nil, line: 2, character: 28),
                       end: Location(file: nil, line: .max, character: .max),
                       disabledRuleIdentifiers: [])
            ])
        }
        // enable/disable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:enable rule_id\n// swiftlint:disable rule_id\n")
            XCTAssertEqual(file.regions(), [
                Region(start: Location(file: nil, line: 1, character: 28),
                       end: Location(file: nil, line: 2, character: 28),
                       disabledRuleIdentifiers: []),
                Region(start: Location(file: nil, line: 2, character: 29),
                       end: Location(file: nil, line: .max, character: .max),
                       disabledRuleIdentifiers: ["rule_id"])
            ])
        }
    }

    func testRegionsFromThreeCommandForSingleLine() {
        let file = SwiftLintFile(contents: "// swiftlint:disable:next 1\n" +
                                  "// swiftlint:disable:this 2\n" +
                                  "// swiftlint:disable:previous 3\n")
        XCTAssertEqual(file.regions(), [
            Region(start: Location(file: nil, line: 2, character: nil),
                   end: Location(file: nil, line: 2, character: .max - 1),
                   disabledRuleIdentifiers: ["1", "2", "3"]),
            Region(start: Location(file: nil, line: 2, character: .max),
                   end: Location(file: nil, line: .max, character: .max),
                   disabledRuleIdentifiers: [])
        ])
    }

    func testSeveralRegionsFromSeveralCommands() {
        let file = SwiftLintFile(contents: "// swiftlint:disable 1\n" +
                                  "// swiftlint:disable 2\n" +
                                  "// swiftlint:disable 3\n" +
                                  "// swiftlint:enable 1\n" +
                                  "// swiftlint:enable 2\n" +
                                  "// swiftlint:enable 3\n")
        XCTAssertEqual(file.regions(), [
            Region(start: Location(file: nil, line: 1, character: 23),
                   end: Location(file: nil, line: 2, character: 22),
                   disabledRuleIdentifiers: ["1"]),
            Region(start: Location(file: nil, line: 2, character: 23),
                   end: Location(file: nil, line: 3, character: 22),
                   disabledRuleIdentifiers: ["1", "2"]),
            Region(start: Location(file: nil, line: 3, character: 23),
                   end: Location(file: nil, line: 4, character: 21),
                   disabledRuleIdentifiers: ["1", "2", "3"]),
            Region(start: Location(file: nil, line: 4, character: 22),
                   end: Location(file: nil, line: 5, character: 21),
                   disabledRuleIdentifiers: ["2", "3"]),
            Region(start: Location(file: nil, line: 5, character: 22),
                   end: Location(file: nil, line: 6, character: 21),
                   disabledRuleIdentifiers: ["3"]),
            Region(start: Location(file: nil, line: 6, character: 22),
                   end: Location(file: nil, line: .max, character: .max),
                   disabledRuleIdentifiers: [])
        ])
    }
}
