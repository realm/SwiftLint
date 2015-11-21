//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

private func regex(pattern: String) -> NSRegularExpression {
    // all patterns used for regular expressions in SwiftLint are string literals which have
    // been confirmed to work, so it's ok to force-try here.
    // swiftlint:disable force_try
    return try! NSRegularExpression(pattern: pattern, options: [.AnchorsMatchLines])
    // swiftlint:enable force_try
}

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
                zip(kindsInRange, syntaxKinds).filter({ $0.0 != $0.1 }).isEmpty
        }.map { $0.0 }
    }

    public func matchPattern(pattern: String) -> [(NSRange, [SyntaxKind])] {
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntax = syntaxMap
        let matches = regex(pattern).matchesInString(contents, options: [], range: range)
        return matches.map { match in
            let tokensInRange = syntax.tokens.filter { token in
                NSLocationInRange(token.offset, match.range) ||
                    NSLocationInRange(match.range.location,
                        NSRange(location: token.offset, length: token.length))
            }.map { $0.type }
            let kindsInRange = tokensInRange.flatMap(SyntaxKind.init)
            return (match.range, kindsInRange)
        }
    }

    //Added by S2dent
    /**
    This function returns only matches that are not contained in a syntax kind
    specified.

    - parameter pattern: regex pattern to be matched inside file.
    - parameter excludingSyntaxKinds: syntax kinds the matches to be filtered
    when inside them.

    - returns: An array of [NSRange] objects consisting of regex matches inside
    file contents.
    */
    public func matchPattern(pattern: String,
                             excludingSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntax = syntaxMap
        let matches = regex(pattern).matchesInString(contents, options: [], range: range)
        return matches.filter { match in
            let tokensInRange = syntax.tokens.filter { token in
                NSLocationInRange(token.offset, match.range) ||
                    NSLocationInRange(match.range.location,
                        NSRange(location: token.offset, length: token.length))
            }
            for token in tokensInRange {
                if NSIntersectionRange(NSRange(location: token.offset,
                    length:token.length), match.range).length > 0 &&
                    syntaxKinds.contains(SyntaxKind(rawValue: token.type)!) {
                    return false
                }
            }

            return true
        }.map { $0.range }
    }

    public func validateVariableName(dictionary: XPCDictionary, kind: SwiftDeclarationKind) ->
                                     (name: String, offset: Int)? {
        guard let name = dictionary["key.name"] as? String,
            offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) where
            SwiftDeclarationKind.variableKinds().contains(kind) && !name.hasPrefix("$") else {
                return nil
        }
        return (name.nameStrippingLeadingUnderscoreIfPrivate(dictionary), offset)
    }
}
