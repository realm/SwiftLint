//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

internal func regex(_ pattern: String) -> NSRegularExpression {
    // all patterns used for regular expressions in SwiftLint are string literals which have been
    // confirmed to work, so it's ok to force-try here.

    // swiftlint:disable:next force_try
    return try! .cached(pattern: pattern)
}

extension File {
    internal func regions() -> [Region] {
        var regions = [Region]()
        var disabledRules = Set<String>()
        let commands = self.commands()
        let commandPairs = zip(commands, Array(commands.dropFirst().map(Optional.init)) + [nil])
        for (command, nextCommand) in commandPairs {
            switch command.action {
            case .disable: disabledRules.formUnion(command.ruleIdentifiers)
            case .enable: disabledRules.subtract(command.ruleIdentifiers)
            }
            let start = Location(file: path, line: command.line, character: command.character)
            let end = endOfNextCommand(nextCommand)
            regions.append(Region(start: start, end: end, disabledRuleIdentifiers: disabledRules))
        }
        return regions
    }

    fileprivate func commands() -> [Command] {
        if sourcekitdFailed {
            return []
        }
        let contents = self.contents.bridge()
        return matchPattern("swiftlint:(enable|disable)(:previous|:this|:next)?\\ [^\\n]+",
            withSyntaxKinds: [.comment]).flatMap { range in
                return Command(string: contents, range: range)
            }.flatMap { command in
                return command.expand()
        }
    }

    fileprivate func endOfNextCommand(_ nextCommand: Command?) -> Location {
        guard let nextCommand = nextCommand else {
            return Location(file: path, line: .max, character: .max)
        }
        let nextLine: Int
        let nextCharacter: Int?
        if let nextCommandCharacter = nextCommand.character {
            nextLine = nextCommand.line
            if nextCommandCharacter > 0 {
                nextCharacter = nextCommandCharacter - 1
            } else {
                nextCharacter = nil
            }
        } else {
            nextLine = max(nextCommand.line - 1, 0)
            nextCharacter = .max
        }
        return Location(file: path, line: nextLine, character: nextCharacter)
    }

    internal func matchPattern(_ pattern: String,
                               withSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        return matchPattern(pattern).filter({ $0.1 == syntaxKinds }).map { $0.0 }
    }

    internal func rangesAndTokensMatching(_ pattern: String) -> [(NSRange, [SyntaxToken])] {
        return rangesAndTokensMatching(regex(pattern))
    }

    internal func rangesAndTokensMatching(_ regex: NSRegularExpression) ->
        [(NSRange, [SyntaxToken])] {
        let contents = self.contents.bridge()
        let range = NSRange(location: 0, length: contents.length)
        let syntax = syntaxMap
        return regex.matches(in: self.contents, options: [], range: range).map { match in
            let matchByteRange = contents.NSRangeToByteRange(start: match.range.location,
                length: match.range.length) ?? match.range
            let tokensInRange = syntax.tokensIn(matchByteRange)
            return (match.range, tokensInRange)
        }
    }

    internal func matchPattern(_ pattern: String) -> [(NSRange, [SyntaxKind])] {
        return matchPattern(regex(pattern))
    }

    internal func matchPattern(_ regex: NSRegularExpression) -> [(NSRange, [SyntaxKind])] {
        return rangesAndTokensMatching(regex).map { range, tokens in
            (range, tokens.flatMap { SyntaxKind(rawValue: $0.type) })
        }
    }

    internal func syntaxTokensByLine() -> [[SyntaxToken]]? {
        if sourcekitdFailed {
            return nil
        }
        var results = [[SyntaxToken]](repeating: [], count: lines.count + 1)
        var tokenGenerator = syntaxMap.tokens.makeIterator()
        var lineGenerator = lines.makeIterator()
        var maybeLine = lineGenerator.next()
        var maybeToken = tokenGenerator.next()
        while let line = maybeLine, let token = maybeToken {
            let tokenRange = NSRange(location: token.offset, length: token.length)
            if NSLocationInRange(token.offset, line.byteRange) ||
                NSLocationInRange(line.byteRange.location, tokenRange) {
                    results[line.index].append(token)
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

    internal func syntaxKindsByLine() -> [[SyntaxKind]]? {

        if sourcekitdFailed {
            return nil
        }
        guard let tokens = syntaxTokensByLine() else {
            return nil
        }

        return tokens.map { $0.flatMap { SyntaxKind(rawValue: $0.type) } }

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
    internal func matchPattern(_ pattern: String,
                               excludingSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        return matchPattern(pattern).filter {
            $0.1.filter(syntaxKinds.contains).isEmpty
        }.map { $0.0 }
    }

    internal func matchPattern(_ pattern: String,
                               excludingSyntaxKinds: [SyntaxKind],
                               excludingPattern: String) -> [NSRange] {
        let contents = self.contents.bridge()
        let range = NSRange(location: 0, length: contents.length)
        let matches = matchPattern(pattern, excludingSyntaxKinds: excludingSyntaxKinds)
        if matches.isEmpty {
            return []
        }
        let exclusionRanges = regex(excludingPattern).matches(in: self.contents, options: [],
                                                              range: range).ranges()
        return matches.filter { !$0.intersectsRanges(exclusionRanges) }
    }

    internal func validateVariableName(_ dictionary: [String: SourceKitRepresentable],
                                       kind: SwiftDeclarationKind) -> (name: String, offset: Int)? {
        guard let name = dictionary["key.name"] as? String,
            let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            SwiftDeclarationKind.variableKinds().contains(kind) && !name.hasPrefix("$") else {
                return nil
        }
        return (name.nameStrippingLeadingUnderscoreIfPrivate(dictionary), offset)
    }

    internal func append(_ string: String) {
        guard let stringData = string.data(using: .utf8) else {
            fatalError("can't encode '\(string)' with UTF8")
        }
        guard let path = path, let fileHandle = FileHandle(forWritingAtPath: path) else {
            fatalError("can't write to path '\(self.path)'")
        }
        _ = fileHandle.seekToEndOfFile()
        fileHandle.write(stringData)
        fileHandle.closeFile()
        contents += string
        lines = contents.bridge().lines()
    }

    internal func write(_ string: String) {
        guard string != contents else {
            return
        }
        guard let path = path else {
            fatalError("file needs a path to call write(_:)")
        }
        guard let stringData = string.data(using: .utf8) else {
            fatalError("can't encode '\(string)' with UTF8")
        }
        do {
            try stringData.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            fatalError("can't write file to \(path)")
        }
        contents = string
        lines = contents.bridge().lines()
    }

    internal func ruleEnabledViolatingRanges(_ violatingRanges: [NSRange],
                                             forRule rule: Rule) -> [NSRange] {
        let fileRegions = regions()
        if fileRegions.isEmpty { return violatingRanges }
        let violatingRanges = violatingRanges.filter { range in
            let region = fileRegions.filter {
                $0.contains(Location(file: self, characterOffset: range.location))
            }.first
            return region?.isRuleEnabled(rule) ?? true
        }
        return violatingRanges
    }

    fileprivate func numberOfCommentAndWhitespaceOnlyLines(_ startLine: Int, endLine: Int) -> Int {
        let commentKinds = Set(SyntaxKind.commentKinds())
        return syntaxKindsByLines[startLine...endLine].filter { kinds in
            kinds.filter { !commentKinds.contains($0) }.isEmpty
        }.count
    }

    internal func exceedsLineCountExcludingCommentsAndWhitespace(_ start: Int, _ end: Int,
                                                                 _ limit: Int) -> (Bool, Int) {
        if end - start <= limit {
            return (false, end - start)
        }

        let count = end - start - numberOfCommentAndWhitespaceOnlyLines(start, endLine: end)
        return (count > limit, count)
    }

    internal func correctLegacyRule<R: Rule>(_ rule: R,
                                             patterns: [String: String]) -> [Correction] {
        typealias RangePatternTemplate = (NSRange, String, String)
        let matches: [RangePatternTemplate]
        matches = patterns.flatMap({ pattern, template -> [RangePatternTemplate] in
            return matchPattern(pattern).filter { range, kinds in
                return kinds.first == .identifier &&
                    !ruleEnabledViolatingRanges([range], forRule: rule).isEmpty
            }.map { ($0.0, pattern, template) }
        }).sorted { $0.0.location > $1.0.location } // reversed

        if matches.isEmpty { return [] }

        let description = type(of: rule).description
        var corrections = [Correction]()
        var contents = self.contents

        for (range, pattern, template) in matches {
            contents = regex(pattern).stringByReplacingMatches(in: contents, options: [],
                                                               range: range,
                                                               withTemplate: template)
            let location = Location(file: self, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        write(contents)
        return corrections
    }

}
