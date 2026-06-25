// swiftlint:disable file_length
import Foundation
import SourceKittenFramework
import SwiftLintFramework
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

private extension Command {
    init?(string: String) {
        let nsString = string.bridge()
        guard nsString.length > 7 else { return nil }
        let subString = nsString.substring(with: NSRange(location: 3, length: nsString.length - 4))
        self.init(commandString: subString, line: 1, range: 4..<nsString.length)
    }
}

@Suite(.rulesRegistered)
struct CommandTests { // swiftlint:disable:this type_body_length

    // MARK: Command Creation

    @Test
    func noCommandsInEmptyFile() {
        let file = SwiftLintFile(contents: "")
        #expect(file.commands().isEmpty)
    }

    @Test
    func emptyString() {
        #expect(Command(string: "") == nil)
    }

    @Test
    func disable() {
        let input = "// swiftlint:disable rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<29)
        #expect(file.commands() == [expected])
        #expect(Command(string: input) == expected)
    }

    @Test
    func disablePrevious() {
        let input = "// swiftlint:disable:previous rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<38,
            modifier: .previous)
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func disableThis() {
        let input = "// swiftlint:disable:this rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .disable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<34,
            modifier: .this
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func disableNext() {
        let input = "// swiftlint:disable:next rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .disable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<34,
            modifier: .next
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func enable() {
        let input = "// swiftlint:enable rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .enable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<28
        )
        #expect(file.commands() == [expected])
        #expect(Command(string: input) == expected)
    }

    @Test
    func enablePrevious() {
        let input = "// swiftlint:enable:previous rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .enable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<37,
            modifier: .previous
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func enableThis() {
        let input = "// swiftlint:enable:this rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .enable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<33,
            modifier: .this
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func enableNext() {
        let input = "// swiftlint:enable:next rule_id\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .enable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<33,
            modifier: .next
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func trailingComment() {
        let input = "// swiftlint:enable:next rule_id - Comment\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .enable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<43,
            modifier: .next,
            trailingComment: "Comment"
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func trailingCommentWithUrl() {
        let input =
            "// swiftlint:enable:next rule_id - Comment with URL https://github.com/realm/SwiftLint\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .enable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<87,
            modifier: .next,
            trailingComment: "Comment with URL https://github.com/realm/SwiftLint"
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    @Test
    func trailingCommentUrlOnly() {
        let input = "// swiftlint:enable:next rule_id - https://github.com/realm/SwiftLint\n"
        let file = SwiftLintFile(contents: input)
        let expected = Command(
            action: .enable,
            ruleIdentifiers: ["rule_id"],
            line: 1,
            range: 4..<70,
            modifier: .next,
            trailingComment: "https://github.com/realm/SwiftLint"
        )
        #expect(file.commands() == expected.expand())
        #expect(Command(string: input) == expected)
    }

    // MARK: Action

    @Test
    func actionInverse() {
        #expect(Command.Action.enable.inverse() == .disable)
        #expect(Command.Action.disable.inverse() == .enable)
    }

    // MARK: Command Expansion

    private let completeLine = 0..<Int.max

    @Test
    func noModifierCommandExpandsToItself() {
        do {
            let command = Command(action: .disable, ruleIdentifiers: ["rule_id"])
            #expect(command.expand() == [command])
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["rule_id"])
            #expect(command.expand() == [command])
        }
        do {
            let command = Command(action: .disable, ruleIdentifiers: ["1", "2"])
            #expect(command.expand() == [command])
        }
    }

    @Test
    func expandPreviousCommand() {
        do {
            let command = Command(
                action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
                modifier: .previous)
            let expanded = [
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 0),
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 0, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
        do {
            let command = Command(
                action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
                modifier: .previous)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 0),
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 0, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
        do {
            let command = Command(
                action: .enable, ruleIdentifiers: ["1", "2"], line: 1, range: 4..<48,
                modifier: .previous)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 0),
                Command(action: .disable, ruleIdentifiers: ["1", "2"], line: 0, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
    }

    @Test
    func expandThisCommand() {
        do {
            let command = Command(
                action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
                modifier: .this)
            let expanded = [
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1),
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
        do {
            let command = Command(
                action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
                modifier: .this)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1),
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
        do {
            let command = Command(
                action: .enable, ruleIdentifiers: ["1", "2"], line: 1, range: 4..<48,
                modifier: .this)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 1),
                Command(action: .disable, ruleIdentifiers: ["1", "2"], line: 1, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
    }

    @Test
    func expandNextCommand() {
        do {
            let command = Command(
                action: .disable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
                modifier: .next)
            let expanded = [
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 2),
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 2, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
        do {
            let command = Command(
                action: .enable, ruleIdentifiers: ["rule_id"], line: 1, range: 4..<48,
                modifier: .next)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 2),
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 2, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
        do {
            let command = Command(
                action: .enable, ruleIdentifiers: ["1", "2"], line: 1,
                modifier: .next)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 2),
                Command(action: .disable, ruleIdentifiers: ["1", "2"], line: 2, range: completeLine),
            ]
            #expect(command.expand() == expanded)
        }
    }

    // MARK: Superfluous Disable Command Detection

    @Test
    func superfluousDisableCommands() {
        #expect(
            violations(Example("// swiftlint:disable nesting\nprint(123)\n")).map(\.ruleIdentifier)
                == ["blanket_disable_command", "superfluous_disable_command"]
        )
        #expect(
            violations(Example("// swiftlint:disable:next nesting\nprint(123)\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
        #expect(
            violations(Example("print(123) // swiftlint:disable:this nesting\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
        #expect(
            violations(Example("print(123)\n// swiftlint:disable:previous nesting\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
    }

    @Test
    func disableAllOverridesSuperfluousDisableCommand() {
        #expect(
            violations(
                Example(
                    """
                    // swiftlint:disable all
                    // swiftlint:disable nesting
                    print(123)
                    // swiftlint:enable nesting
                    // swiftlint:enable all
                    """)
            ).isEmpty
        )
        #expect(
            violations(
                Example(
                    """
                    // swiftlint:disable all
                    // swiftlint:disable:next nesting
                    print(123)
                    // swiftlint:enable all
                    """)
            ).isEmpty
        )
        #expect(
            violations(
                Example(
                    """
                    // swiftlint:disable all
                    // swiftlint:disable:this nesting
                    print(123)
                    // swiftlint:enable all
                    """)
            ).isEmpty
        )
        #expect(
            violations(Example("// swiftlint:disable all\n// swiftlint:disable:previous nesting\nprint(123)\n")).isEmpty
        )
    }

    @Test
    func superfluousDisableCommandsIgnoreDelimiter() {
        let longComment =
            "Comment with a large number of words that shouldn't register as superfluous"
        #expect(
            violations(Example("// swiftlint:disable nesting - \(longComment)\nprint(123)\n")).map(\.ruleIdentifier)
                == ["blanket_disable_command", "superfluous_disable_command"]
        )
        #expect(
            violations(Example("// swiftlint:disable:next nesting - Comment\nprint(123)\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
        #expect(
            violations(Example("print(123) // swiftlint:disable:this nesting - Comment\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
        #expect(
            violations(Example("print(123)\n// swiftlint:disable:previous nesting - Comment\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
    }

    @Test
    func invalidDisableCommands() {
        #expect(
            violations(
                Example(
                    "// swiftlint:disable nesting_foo\n" + "print(123)\n"
                        + "// swiftlint:enable nesting_foo\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
        #expect(
            violations(Example("// swiftlint:disable:next nesting_foo\nprint(123)\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
        #expect(
            violations(Example("print(123) // swiftlint:disable:this nesting_foo\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )
        #expect(
            violations(Example("print(123)\n// swiftlint:disable:previous nesting_foo\n")).map(\.ruleIdentifier)
                == ["superfluous_disable_command"]
        )

        #expect(violations(Example("print(123)\n// swiftlint:disable:previous nesting_foo \n")).count == 1)

        let example = Example(
            "// swiftlint:disable nesting this is a comment\n// swiftlint:enable nesting\n")
        let multipleViolations = violations(example)
        #expect(multipleViolations.filter({ $0.ruleIdentifier == "superfluous_disable_command" }).count == 9)
        #expect(multipleViolations.filter({ $0.ruleIdentifier == "blanket_disable_command" }).count == 4)

        let onlyNonExistentRulesViolations = violations(
            Example("// swiftlint:disable this is a comment\n"))
        #expect(
            onlyNonExistentRulesViolations.filter({
                $0.ruleIdentifier == "superfluous_disable_command"
            }).count == 4
        )
        #expect(
            onlyNonExistentRulesViolations.filter({
                $0.ruleIdentifier == "blanket_disable_command"
            }).count == 4)

        #expect(
            violations(Example("print(123)\n// swiftlint:disable:previous nesting_foo\n")).first?.reason
                == "'nesting_foo' is not a valid SwiftLint rule; remove it from the disable command"
        )
    }

    @Test
    func superfluousDisableCommandsDisabled() {
        #expect(
            violations(
                Example(
                    "// swiftlint:disable superfluous_disable_command nesting\n" + "print(123)\n"
                        + "// swiftlint:enable superfluous_disable_command nesting\n")
                ).isEmpty
        )
        #expect(
            violations(
                Example(
                    "// swiftlint:disable superfluous_disable_command\n"
                        + "// swiftlint:disable nesting\n" + "print(123)\n"
                        + "// swiftlint:enable superfluous_disable_command nesting\n")
            ).isEmpty
        )
        #expect(
            violations(
                Example(
                    "// swiftlint:disable:next superfluous_disable_command nesting\nprint(123)\n")
                ).isEmpty
        )
        #expect(
            violations(
                Example(
                    "print(123) // swiftlint:disable:this superfluous_disable_command nesting\n")
                ).isEmpty
        )
        #expect(
            violations(
                Example(
                    "print(123)\n// swiftlint:disable:previous superfluous_disable_command nesting\n"
                )
            ).isEmpty
        )
    }

    @Test
    func superfluousDisableCommandsDisabledOnConfiguration() {
        let rulesMode = Configuration.RulesMode.defaultConfiguration(
            disabled: ["superfluous_disable_command"], optIn: []
        )
        let configuration = Configuration(rulesMode: rulesMode)

        #expect(
            violations(
                Example(
                    "// swiftlint:disable nesting\n" + "print(123)\n"
                        + "// swiftlint:enable nesting\n"), config: configuration
                ).isEmpty
        )
        #expect(
            violations(Example("// swiftlint:disable:next nesting\nprint(123)\n"), config: configuration).isEmpty
        )
        #expect(
            violations(Example("print(123) // swiftlint:disable:this nesting\n"), config: configuration).isEmpty
        )
        #expect(
            violations(Example("print(123)\n// swiftlint:disable:previous nesting\n"), config: configuration).isEmpty
        )
    }

    @Test
    func superfluousDisableCommandsDisabledWhenAllRulesDisabled() {
        #expect(
            violations(
                Example(
                    """
                    // swiftlint:disable all
                    // swiftlint:disable non_existent_rule_name
                    // swiftlint:enable non_existent_rule_name
                    // swiftlint:enable all
                    """
                )
            ).isEmpty
        )
        #expect(
            violations(
                Example(
                    """
                    // swiftlint:disable superfluous_disable_command
                    // swiftlint:disable non_existent_rule_name
                    // swiftlint:enable non_existent_rule_name
                    // swiftlint:enable superfluous_disable_command

                    """
                )
            ).isEmpty
        )
    }

    @Test
    func superfluousDisableCommandsInMultilineComments() {
        #expect(
            violations(
                Example(
                    """
                    /*
                    // swiftlint:disable identifier_name
                    let a = 0
                    */

                    """
                )
            ).isEmpty
        )
    }

    @Test
    func superfluousDisableCommandsEnabledForAnalyzer() {
        let configuration = Configuration(
            rulesMode: .defaultConfiguration(disabled: [], optIn: [UnusedDeclarationRule.identifier])
        )
        let violations = violations(
            Example(
                """
                public class Foo {
                    // swiftlint:disable:next unused_declaration
                    func foo() -> Int {
                        1
                    }
                    // swiftlint:disable:next unused_declaration
                    func bar() {
                       foo()
                    }
                }
                """),
            config: configuration,
            requiresFileOnDisk: true
        )
        #expect(violations.count == 1)
        #expect(violations.first?.ruleIdentifier == "superfluous_disable_command")
        #expect(violations.first?.location.line == 3)
    }
}
