//
//  Command.swift
//  SwiftLint
//
//  Created by JP Simard on 8/29/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public enum CommandAction: String {
    case Enable = "enable"
    case Disable = "disable"

    fileprivate func inverse() -> CommandAction {
        switch self {
        case .Enable: return .Disable
        case .Disable: return .Enable
        }
    }
}

public enum CommandModifier: String {
    case Previous = "previous"
    case This = "this"
    case Next = "next"
}

public struct Command {
    let action: CommandAction
    let ruleIdentifier: String
    let line: Int
    let character: Int?
    let modifier: CommandModifier?

    public init(action: CommandAction, ruleIdentifier: String, line: Int = 0, character: Int? = nil,
                modifier: CommandModifier? = nil) {
        self.action = action
        self.ruleIdentifier = ruleIdentifier
        self.line = line
        self.character = character
        self.modifier = modifier
    }

    public init?(string: NSString, range: NSRange) {
        let scanner = Scanner(string: string.substring(with: range))
        scanner.scanString("swiftlint:", into: nil)
        var optionalActionAndModifierNSString: NSString? = nil
        scanner.scanUpTo(" ", into: &optionalActionAndModifierNSString)
        guard let actionAndModifierString = optionalActionAndModifierNSString as String? else {
            return nil
        }
        let actionAndModifierScanner = Scanner(string: actionAndModifierString)
        var actionNSString: NSString? = nil
        actionAndModifierScanner.scanUpTo(":", into: &actionNSString)
        guard let actionString = actionNSString as String?,
            let action = CommandAction(rawValue: actionString),
            let lineAndCharacter = string.lineAndCharacterForCharacterOffset(NSMaxRange(range)) else {
                return nil
        }
        self.action = action
        ruleIdentifier = (scanner.string as NSString).substring(from: scanner.scanLocation + 1)
        line = lineAndCharacter.line
        character = lineAndCharacter.character

        let hasModifier = actionAndModifierScanner.scanString(":", into: nil)

        // Modifier
        if hasModifier {
            let modifierString = (actionAndModifierScanner.string as NSString)
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
        case .Previous:
            return [
                Command(action: action, ruleIdentifier: ruleIdentifier, line: line - 1),
                Command(action: action.inverse(), ruleIdentifier: ruleIdentifier, line: line - 1,
                    character: Int.max)
            ]
        case .This:
            return [
                Command(action: action, ruleIdentifier: ruleIdentifier, line: line),
                Command(action: action.inverse(), ruleIdentifier: ruleIdentifier, line: line,
                    character: Int.max)
            ]
        case .Next:
            return [
                Command(action: action, ruleIdentifier: ruleIdentifier, line: line + 1),
                Command(action: action.inverse(), ruleIdentifier: ruleIdentifier, line: line + 1,
                    character: Int.max)
            ]
        }
    }
}
