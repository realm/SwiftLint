//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

extension File {
    public func regions() -> [Region] {
        let nsStringContents = contents as NSString
        let commands = matchPattern("swiftlint:(enable|disable)\\ [^\\s]+",
            withSyntaxKinds: [.Comment]).flatMap { Command(string: nsStringContents, range: $0) }
        let totalNumberOfLines = lines.count
        let numberOfCharactersInLastLine = lines.last?.content.characters.count
        var regions = [Region]()
        var disabledRules = Set<String>()
        let commandPairs = zip(commands, Array(commands.dropFirst().map({Optional($0)})) + [nil])
        for (command, nextCommand) in commandPairs {
            switch command.action {
            case .Disable: disabledRules.insert(command.ruleIdentifier)
            case .Enable: disabledRules.remove(command.ruleIdentifier)
            }
            regions.append(
                Region(
                    start: Location(file: path,
                        line: command.line,
                        character: command.character),
                    end: Location(file: path,
                        line: nextCommand?.line ?? totalNumberOfLines,
                        character: nextCommand?.character ?? numberOfCharactersInLastLine),
                    disabledRuleIdentifiers: disabledRules)
            )
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
                NSLocationInRange($0.offset, match.range) ||
                    NSLocationInRange(match.range.location,
                        NSRange(location: $0.offset, length: $0.length))
            }
            let kindsInRange = tokensInRange.flatMap {
                SyntaxKind(rawValue: $0.type)
            }
            return (match.range, kindsInRange)
        }
    }
}
