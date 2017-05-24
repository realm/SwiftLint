//
//  Command.swift
//  SwiftLint
//
//  Created by JP Simard on 8/29/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

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

public struct Command: Equatable {
    public enum Action: String {
        case enable
        case disable

        internal func inverse() -> Action {
            switch self {
            case .enable: return .disable
            case .disable: return .enable
            }
        }
    }

    public enum Modifier: String {
        case previous
        case this
        case next
    }

    internal let action: Action
    internal let ruleIdentifiers: [String]
    internal let line: Int
    internal let character: Int?
    internal let modifier: Modifier?

    public init(action: Action, ruleIdentifiers: [String], line: Int = 0,
                character: Int? = nil, modifier: Modifier? = nil) {
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
            let action = Action(rawValue: actionString),
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
            modifier = Modifier(rawValue: modifierString)
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

// MARK: Equatable

public func == (lhs: Command, rhs: Command) -> Bool {
    return lhs.action == rhs.action &&
        lhs.ruleIdentifiers == rhs.ruleIdentifiers &&
        lhs.line == rhs.line &&
        lhs.character == rhs.character &&
        lhs.modifier == rhs.modifier
}
