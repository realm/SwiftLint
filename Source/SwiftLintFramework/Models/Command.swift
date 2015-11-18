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
}

public struct Command {
    let action: CommandAction
    let ruleIdentifier: String
    let line: Int
    let character: Int

    public init(action: CommandAction, ruleIdentifier: String, line: Int, character: Int) {
        self.action = action
        self.ruleIdentifier = ruleIdentifier
        self.line = line
        self.character = character
    }

    public init?(string: NSString, range: NSRange) {
        let scanner = NSScanner(string: string.substringWithRange(range))
        scanner.scanString("swiftlint:", intoString: nil)
        var actionNSString: NSString? = nil
        scanner.scanUpToString(" ", intoString: &actionNSString)
        guard let actionString = actionNSString as String?,
            action = CommandAction(rawValue: actionString),
            lineAndCharacter = string.lineAndCharacterForCharacterOffset(NSMaxRange(range)) else {
                return nil
        }
        self.action = action
        let ruleStart = scanner.string.startIndex.advancedBy(scanner.scanLocation + 1)
        ruleIdentifier = scanner.string.substringFromIndex(ruleStart)
        line = lineAndCharacter.line
        character = lineAndCharacter.character
    }
}
