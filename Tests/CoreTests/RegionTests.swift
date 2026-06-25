import SwiftLintCore
import Testing

@Suite
struct RegionTests {
    @Test
    func noRegionsInEmptyFile() {
        let file = SwiftLintFile(contents: "")
        #expect(file.regions().isEmpty)
    }

    @Test
    func noRegionsInFileWithNoCommands() {
        let file = SwiftLintFile(contents: String(repeating: "\n", count: 100))
        #expect(file.regions().isEmpty)
    }

    @Test
    func regionsFromSingleCommand() {
        // disable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:disable rule_id\n")
            let start = Location(file: nil, line: 1, character: 29)
            let end = Location(file: nil, line: .max, character: .max)
            #expect(file.regions() == [Region(start: start, end: end, disabledRuleIdentifiers: ["rule_id"])])
        }
        // enable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:enable rule_id\n")
            let start = Location(file: nil, line: 1, character: 28)
            let end = Location(file: nil, line: .max, character: .max)
            #expect(file.regions() == [Region(start: start, end: end, disabledRuleIdentifiers: [])])
        }
    }

    @Test
    func regionsFromMatchingPairCommands() {
        // disable/enable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:disable rule_id\n// swiftlint:enable rule_id\n")
            #expect(file.regions() == [
                Region(
                    start: Location(file: nil, line: 1, character: 29),
                    end: Location(file: nil, line: 2, character: 27),
                    disabledRuleIdentifiers: ["rule_id"]),
                Region(
                    start: Location(file: nil, line: 2, character: 28),
                    end: Location(file: nil, line: .max, character: .max),
                    disabledRuleIdentifiers: []),
            ])
        }
        // enable/disable
        do {
            let file = SwiftLintFile(contents: "// swiftlint:enable rule_id\n// swiftlint:disable rule_id\n")
            #expect(file.regions() == [
                Region(
                    start: Location(file: nil, line: 1, character: 28),
                    end: Location(file: nil, line: 2, character: 28),
                    disabledRuleIdentifiers: []),
                Region(
                    start: Location(file: nil, line: 2, character: 29),
                    end: Location(file: nil, line: .max, character: .max),
                    disabledRuleIdentifiers: ["rule_id"]),
            ])
        }
    }

    @Test
    func regionsFromThreeCommandForSingleLine() {
        let file = SwiftLintFile(
            contents: "// swiftlint:disable:next 1\n" + "// swiftlint:disable:this 2\n"
                + "// swiftlint:disable:previous 3\n")
        #expect(file.regions() == [
            Region(
                start: Location(file: nil, line: 2, character: nil),
                end: Location(file: nil, line: 2, character: .max - 1),
                disabledRuleIdentifiers: ["1", "2", "3"]),
            Region(
                start: Location(file: nil, line: 2, character: .max),
                end: Location(file: nil, line: .max, character: .max),
                disabledRuleIdentifiers: []),
        ])
    }

    @Test
    func severalRegionsFromSeveralCommands() {
        let file = SwiftLintFile(contents: """
            // swiftlint:disable 1
            // swiftlint:disable 2
            // swiftlint:disable 3
            // swiftlint:enable 1
            // swiftlint:enable 2
            // swiftlint:enable 3
            """
        )
        #expect(file.regions() == [
            Region(
                start: Location(file: nil, line: 1, character: 23),
                end: Location(file: nil, line: 2, character: 22),
                disabledRuleIdentifiers: ["1"]),
            Region(
                start: Location(file: nil, line: 2, character: 23),
                end: Location(file: nil, line: 3, character: 22),
                disabledRuleIdentifiers: ["1", "2"]),
            Region(
                start: Location(file: nil, line: 3, character: 23),
                end: Location(file: nil, line: 4, character: 21),
                disabledRuleIdentifiers: ["1", "2", "3"]),
            Region(
                start: Location(file: nil, line: 4, character: 22),
                end: Location(file: nil, line: 5, character: 21),
                disabledRuleIdentifiers: ["2", "3"]),
            Region(
                start: Location(file: nil, line: 5, character: 22),
                end: Location(file: nil, line: 6, character: 21),
                disabledRuleIdentifiers: ["3"]),
            Region(
                start: Location(file: nil, line: 6, character: 22),
                end: Location(file: nil, line: .max, character: .max),
                disabledRuleIdentifiers: []),
        ])
    }
}
