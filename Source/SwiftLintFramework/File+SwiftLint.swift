//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public typealias Line = (index: Int, content: String)

public typealias Region = (startLine: Int, endLine: Int, disabledRules: [String])

public enum CommandAction: String {
    case Enable = "enable"
    case Disable = "disable"
}

public typealias Command = (CommandAction, String, Int)

extension File {
    public func regions() -> [Region] {
        let nsStringContents = contents as NSString
        let commands = matchPattern("swiftlint:(enable|disable):force_cast")
            .flatMap { range, syntaxKinds -> Command? in
                let scanner = NSScanner(string: nsStringContents.substringWithRange(range))
                scanner.scanString("swiftlint:", intoString: nil)
                var actionString: NSString? = nil
                scanner.scanUpToString(":", intoString: &actionString)
                let start = range.location
                if let actionString = actionString as String?,
                    action = CommandAction(rawValue: actionString),
                    lineRange = nsStringContents.lineRangeWithByteRange(start: start, length: 0) {
                        scanner.scanString(":", intoString: nil)
                        let ruleStart = scanner.string.startIndex.advancedBy(scanner.scanLocation)
                        let rule = scanner.string.substringFromIndex(ruleStart)
                        return (action, rule, lineRange.start)
                }
                return nil
        }
        let totalNumberOfLines = contents.lines().count
        var regions: [Region] = [(1, commands.first?.2 ?? totalNumberOfLines, [])]
        var disabledRules = Set<String>()
        let commandPairs = zip(commands, Array(commands.dropFirst().map({Optional($0)})) + [nil])
        for (command, nextCommand) in commandPairs {
            switch command.0 {
            case .Disable: disabledRules.insert(command.1)
            case .Enable: disabledRules.remove(command.1)
            }
            regions.append((command.2, nextCommand?.2 ?? totalNumberOfLines, Array(disabledRules)))
        }
        return regions
    }

    public func matchPattern(pattern: String,
        withSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        return matchPattern(pattern).filter { _, kindsInRange in
            return kindsInRange.count == syntaxKinds.count &&
                zip(kindsInRange, syntaxKinds).filter({ $0.0 != $0.1 }).count == 0
        }.map { $0.0 }
    }

    public func matchPattern(pattern: String) -> [(NSRange, [SyntaxKind])] {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntax = syntaxMap
        let matches = regex.matchesInString(contents, options: [], range: range)
        return matches.map { match in
            let tokensInRange = syntax.tokens.filter {
                NSLocationInRange($0.offset, match.range)
            }
            let kindsInRange = tokensInRange.flatMap {
                SyntaxKind(rawValue: $0.type)
            }
            return (match.range, kindsInRange)
        }
    }
}
