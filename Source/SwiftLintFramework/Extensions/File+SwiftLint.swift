//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

internal func regex(pattern: String) -> NSRegularExpression {
    // all patterns used for regular expressions in SwiftLint are string literals which have been
    // confirmed to work, so it's ok to force-try here.

    // swiftlint:disable:next force_try
    return try! NSRegularExpression.cached(pattern: pattern)
}

extension File {
    internal func regions() -> [Region] {
        var regions = [Region]()
        var disabledRules = Set<String>()
        let commands = self.commands()
        let commandPairs = zip(commands, Array(commands.dropFirst().map(Optional.init)) + [nil])
        for (command, nextCommand) in commandPairs {
            switch command.action {
            case .Disable: disabledRules.insert(command.ruleIdentifier)
            case .Enable: disabledRules.remove(command.ruleIdentifier)
            }
            let start = Location(file: path, line: command.line, character: command.character)
            let end = endOfNextCommand(nextCommand)
            regions.append(Region(start: start, end: end, disabledRuleIdentifiers: disabledRules))
        }
        return regions
    }

    private func commands() -> [Command] {
        if sourcekitdFailed {
            return []
        }
        let contents = self.contents as NSString
        return matchPattern("swiftlint:(enable|disable)(:previous|:this|:next)?\\ [^\\s]+",
            withSyntaxKinds: [.Comment]).flatMap { range in
                return Command(string: contents, range: range)
            }.flatMap { command in
                return command.expand()
        }
    }

    private func endOfNextCommand(nextCommand: Command?) -> Location {
        guard let nextCommand = nextCommand else {
            return Location(file: path, line: Int.max, character: Int.max)
        }
        let nextLine: Int
        let nextCharacter: Int?
        if let nextCommandCharacter = nextCommand.character {
            nextLine = nextCommand.line
            if nextCommand.character > 0 {
                nextCharacter = nextCommandCharacter - 1
            } else {
                nextCharacter = nil
            }
        } else {
            nextLine = max(nextCommand.line - 1, 0)
            nextCharacter = Int.max
        }
        return Location(file: path, line: nextLine, character: nextCharacter)
    }

    internal func matchPattern(pattern: String,
                             withSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        return matchPattern(pattern).filter { _, kindsInRange in
            return kindsInRange.count == syntaxKinds.count &&
                zip(kindsInRange, syntaxKinds).filter({ $0.0 != $0.1 }).isEmpty
        }.map { $0.0 }
    }

    internal func rangesAndTokensMatching(pattern: String) -> [(NSRange, [SyntaxToken])] {
        return rangesAndTokensMatching(regex(pattern))
    }

    internal func rangesAndTokensMatching(regex: NSRegularExpression) ->
        [(NSRange, [SyntaxToken])] {
        let contents = self.contents as NSString
        let range = NSRange(location: 0, length: contents.length)
        let syntax = syntaxMap
        return regex.matchesInString(self.contents, options: [], range: range).map { match in
            let matchByteRange = contents.NSRangeToByteRange(start: match.range.location,
                length: match.range.length) ?? match.range
            let tokensInRange = syntax.tokensIn(matchByteRange)
            return (match.range, tokensInRange)
        }
    }

    internal func matchPattern(pattern: String) -> [(NSRange, [SyntaxKind])] {
        return matchPattern(regex(pattern))
    }

    internal func matchPattern(regex: NSRegularExpression) -> [(NSRange, [SyntaxKind])] {
        return rangesAndTokensMatching(regex).map { range, tokens in
            (range, tokens.map({ $0.type }).flatMap(SyntaxKind.init))
        }
    }

    internal func syntaxKindsByLine() -> [[SyntaxKind]]? {
        if sourcekitdFailed {
            return nil
        }
        var results = [[SyntaxKind]](count: lines.count + 1, repeatedValue: [])
        var tokenGenerator = syntaxMap.tokens.generate()
        var lineGenerator = lines.generate()
        var maybeLine = lineGenerator.next()
        var maybeToken = tokenGenerator.next()
        while let line = maybeLine, token = maybeToken {
            let tokenRange = NSRange(location: token.offset, length: token.length)
            if NSLocationInRange(token.offset, line.byteRange) ||
                NSLocationInRange(line.byteRange.location, tokenRange) {
                    results[line.index].append(SyntaxKind(rawValue: token.type)!)
            }
            let tokenEnd = NSMaxRange(tokenRange)
            let lineEnd = NSMaxRange(line.byteRange)
            if tokenEnd < lineEnd {
                maybeToken = tokenGenerator.next()
            } else if tokenEnd > lineEnd {
                maybeLine = lineGenerator.next()
            } else {
                maybeLine = lineGenerator.next()
                maybeToken = tokenGenerator.next()
            }
        }
        return results
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
    internal func matchPattern(pattern: String,
                             excludingSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        return matchPattern(pattern).filter {
            $0.1.filter(syntaxKinds.contains).isEmpty
        }.map { $0.0 }
    }

    internal func matchPattern(pattern: String,
                             excludingSyntaxKinds: [SyntaxKind],
                             excludingPattern: String) -> [NSRange] {
        let contents = self.contents as NSString
        let range = NSRange(location: 0, length: contents.length)
        let matches = matchPattern(pattern, excludingSyntaxKinds: excludingSyntaxKinds)
        if matches.isEmpty {
            return []
        }
        let exclusionRanges = regex(excludingPattern).matchesInString(self.contents,
                                                                      options: [],
                                                                      range: range)
                                                                            .ranges()
        return matches.filter { !$0.intersectsRanges(exclusionRanges) }
    }

    internal func validateVariableName(dictionary: [String: SourceKitRepresentable],
                                     kind: SwiftDeclarationKind) -> (name: String, offset: Int)? {
        guard let name = dictionary["key.name"] as? String,
            offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) where
            SwiftDeclarationKind.variableKinds().contains(kind) && !name.hasPrefix("$") else {
                return nil
        }
        return (name.nameStrippingLeadingUnderscoreIfPrivate(dictionary), offset)
    }

    internal func append(string: String) {
        guard let stringData = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            fatalError("can't encode '\(string)' with UTF8")
        }
        guard let path = path, fileHandle = NSFileHandle(forWritingAtPath: path) else {
            fatalError("can't write to path '\(self.path)'")
        }
        fileHandle.seekToEndOfFile()
        fileHandle.writeData(stringData)
        fileHandle.closeFile()
        contents += string
        lines = contents.lines()
    }

    internal func write(string: String) {
        guard string != contents else {
            return
        }
        guard let path = path else {
            fatalError("file needs a path to call write(_:)")
        }
        guard let stringData = string.dataUsingEncoding(NSUTF8StringEncoding) else {
            fatalError("can't encode '\(string)' with UTF8")
        }
        stringData.writeToFile(path, atomically: true)
        contents = string
        lines = contents.lines()
    }

    internal func ruleEnabledViolatingRanges(violatingRanges: [NSRange], forRule rule: Rule)
        -> [NSRange] {
        let fileRegions = regions()
        let violatingRanges = violatingRanges.filter { range in
            let region = fileRegions.filter {
                $0.contains(Location(file: self, characterOffset: range.location))
            }.first
            return region?.isRuleEnabled(rule) ?? true
        }
        return violatingRanges
    }

    private func numberOfCommentAndWhitespaceOnlyLines(startLine: Int, endLine: Int) -> Int {
        let commentKinds = Set(SyntaxKind.commentKinds())
        return syntaxKindsByLines[startLine...endLine].filter { kinds in
            kinds.filter { !commentKinds.contains($0) }.isEmpty
        }.count
    }

    internal func exceedsLineCountExcludingCommentsAndWhitespace(start: Int, _ end: Int,
                                                                 _ limit: Int) -> (Bool, Int) {
        if end - start <= limit {
            return (false, end - start)
        }

        let count = end - start - numberOfCommentAndWhitespaceOnlyLines(start, endLine: end)
        return (count > limit, count)
    }
}
