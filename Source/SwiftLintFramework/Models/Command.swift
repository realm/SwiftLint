//
//  Command.swift
//  SwiftLint
//
//  Created by JP Simard on 8/29/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public enum CommandAction: String {
    case enable
    case disable

    fileprivate func inverse() -> CommandAction {
        switch self {
        case .enable: return .disable
        case .disable: return .enable
        }
    }
}

public enum CommandModifier: String {
    case previous
    case this
    case next
}

#if !os(Linux)
private extension Scanner {
    func scanUpToString(_ string: String) -> String? {
        var result: NSString? = nil
        let success = scanUpTo(string, into: &result)
        if success {
            return result?.bridge()
        }
        return nil
    }

    func scanString(string: String) -> String? {
        var result: NSString? = nil
        let success = scanString(string, into: &result)
        if success {
            return result?.bridge()
        }
        return nil
    }
}
#endif

public struct Command {
    let action: CommandAction
    let ruleIdentifiers: [String]
    let line: Int
    let character: Int?
    let modifier: CommandModifier?

    public init(action: CommandAction, ruleIdentifiers: [String], line: Int = 0,
                character: Int? = nil, modifier: CommandModifier? = nil) {
        self.action = action
        self.ruleIdentifiers = ruleIdentifiers
        self.line = line
        self.character = character
        self.modifier = modifier
    }

    public init?(string: NSString, range: NSRange) {
        let scanner = Scanner(string: string.substring(with: range))
        _ = scanner.scanString(string: "swiftlint:")
        guard let actionAndModifierString = scanner.scanUpToString(" ") else {
            return nil
        }
        let actionAndModifierScanner = Scanner(string: actionAndModifierString)
        guard let actionString = actionAndModifierScanner.scanUpToString(":"),
            let action = CommandAction(rawValue: actionString),
            let lineAndCharacter = string.lineAndCharacter(forCharacterOffset: NSMaxRange(range))
            else {
                return nil
        }
        self.action = action
        ruleIdentifiers = scanner.string.bridge()
            .substring(from: scanner.scanLocation + 1)
            .components(separatedBy: .whitespaces)
        line = lineAndCharacter.line
        character = lineAndCharacter.character

        let hasModifier = actionAndModifierScanner.scanString(string: ":") != nil

        // Modifier
        if hasModifier {
            let modifierString = actionAndModifierScanner.string.bridge()
                .substring(from: actionAndModifierScanner.scanLocation)
            modifier = CommandModifier(rawValue: modifierString)
        } else {
            modifier = nil
        }
    }

    internal func expand() -> [Command] {
        guard let modifier = modifier else {
            return [self]
        }
        switch modifier {
        case .previous:
            return [
                Command(action: action, ruleIdentifiers: ruleIdentifiers, line: line - 1),
                Command(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line - 1,
                    character: Int.max)
            ]
        case .this:
            return [
                Command(action: action, ruleIdentifiers: ruleIdentifiers, line: line),
                Command(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line,
                    character: Int.max)
            ]
        case .next:
            return [
                Command(action: action, ruleIdentifiers: ruleIdentifiers, line: line + 1),
                Command(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line + 1,
                    character: Int.max)
            ]
        }
    }
}
