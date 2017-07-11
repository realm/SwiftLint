//
//  CommandTests.swift
//  SwiftLint
//
//  Created by JP Simard on 5/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

private extension Command {
    init?(string: String) {
        let nsString = string.bridge()
        self.init(string: nsString, range: NSRange(location: 3, length: nsString.length - 4))
    }
}

internal class CommandTests: XCTestCase {

    // MARK: Command Creation

    func testNoCommandsInEmptyFile() {
        let file = File(contents: "")
        XCTAssertEqual(file.commands(), [])
    }

    func testEmptyString() {
        XCTAssertNil(Command(string: "", range: NSRange(location: 0, length: 0)))
    }

    func testDisable() {
        let input = "// swiftlint:disable rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: 29, modifier: nil)
        XCTAssertEqual(file.commands(), [expected])
        XCTAssertEqual(Command(string: input), expected)
    }

    func testDisablePrevious() {
        let input = "// swiftlint:disable:previous rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: 38,
                               modifier: .previous)
        XCTAssertEqual(file.commands(), expected.expand())
        XCTAssertEqual(Command(string: input), expected)
    }

    func testDisableThis() {
        let input = "// swiftlint:disable:this rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: 34, modifier: .this)
        XCTAssertEqual(file.commands(), expected.expand())
        XCTAssertEqual(Command(string: input), expected)
    }

    func testDisableNext() {
        let input = "// swiftlint:disable:next rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: 34, modifier: .next)
        XCTAssertEqual(file.commands(), expected.expand())
        XCTAssertEqual(Command(string: input), expected)
    }

    func testEnable() {
        let input = "// swiftlint:enable rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: 28, modifier: nil)
        XCTAssertEqual(file.commands(), [expected])
        XCTAssertEqual(Command(string: input), expected)
    }

    func testEnablePrevious() {
        let input = "// swiftlint:enable:previous rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: 37,
                               modifier: .previous)
        XCTAssertEqual(file.commands(), expected.expand())
        XCTAssertEqual(Command(string: input), expected)
    }

    func testEnableThis() {
        let input = "// swiftlint:enable:this rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: 33, modifier: .this)
        XCTAssertEqual(file.commands(), expected.expand())
        XCTAssertEqual(Command(string: input), expected)
    }

    func testEnableNext() {
        let input = "// swiftlint:enable:next rule_id\n"
        let file = File(contents: input)
        let expected = Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: 33, modifier: .next)
        XCTAssertEqual(file.commands(), expected.expand())
        XCTAssertEqual(Command(string: input), expected)
    }

    // MARK: Action

    func testActionInverse() {
        XCTAssertEqual(Command.Action.enable.inverse(), .disable)
        XCTAssertEqual(Command.Action.disable.inverse(), .enable)
    }

    // MARK: Command Expansion

    func testNoModifierCommandExpandsToItself() {
        do {
            let command = Command(action: .disable, ruleIdentifiers: ["rule_id"])
            XCTAssertEqual(command.expand(), [command])
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["rule_id"])
            XCTAssertEqual(command.expand(), [command])
        }
        do {
            let command = Command(action: .disable, ruleIdentifiers: ["1", "2"])
            XCTAssertEqual(command.expand(), [command])
        }
    }

    func testExpandPreviousCommand() {
        do {
            let command = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: 38,
                                  modifier: .previous)
            let expanded = [
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 0, character: nil),
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 0, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: 38,
                                  modifier: .previous)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 0, character: nil),
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 0, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 1, character: 38,
                                  modifier: .previous)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 0, character: nil),
                Command(action: .disable, ruleIdentifiers: ["1", "2"], line: 0, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
    }

    func testExpandThisCommand() {
        do {
            let command = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: 38,
                                  modifier: .this)
            let expanded = [
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: nil),
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: 38,
                                  modifier: .this)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: nil),
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 1, character: 38,
                                  modifier: .this)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 1, character: nil),
                Command(action: .disable, ruleIdentifiers: ["1", "2"], line: 1, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
    }

    func testExpandNextCommand() {
        do {
            let command = Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 1, character: 38,
                                  modifier: .next)
            let expanded = [
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 2, character: nil),
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 2, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 1, character: 38,
                                  modifier: .next)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["rule_id"], line: 2, character: nil),
                Command(action: .disable, ruleIdentifiers: ["rule_id"], line: 2, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
        do {
            let command = Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 1, character: 38,
                                  modifier: .next)
            let expanded = [
                Command(action: .enable, ruleIdentifiers: ["1", "2"], line: 2, character: nil),
                Command(action: .disable, ruleIdentifiers: ["1", "2"], line: 2, character: .max)
            ]
            XCTAssertEqual(command.expand(), expanded)
        }
    }
}
