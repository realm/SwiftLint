//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

internal func regex(_ pattern: String,
                    options: NSRegularExpression.Options? = nil) -> NSRegularExpression {
    // all patterns used for regular expressions in SwiftLint are string literals which have been
    // confirmed to work, so it's ok to force-try here.

    let options = options ?? [.anchorsMatchLines, .dotMatchesLineSeparators]
    // swiftlint:disable:next force_try
    return try! .cached(pattern: pattern, options: options)
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
            let end = endOf(next: nextCommand)
            regions.append(Region(start: start, end: end, disabledRuleIdentifiers: disabledRules))
        }
        return regions
    }

    fileprivate func commands() -> [Command] {
        if sourcekitdFailed {
            return []
        }
        let contents = self.contents.bridge()
        let pattern = "swiftlint:(enable|disable)(:previous|:this|:next)?\\ [^\\n]+"
        return match(pattern: pattern, with: [.comment]).flatMap { range in
            return Command(string: contents, range: range)
        }.flatMap { command in
            return command.expand()
        }
    }

    fileprivate func endOf(next command: Command?) -> Location {
        guard let nextCommand = command else {
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

    internal func match(pattern: String, with syntaxKinds: [SyntaxKind], range: NSRange? = nil) -> [NSRange] {
        return match(pattern: pattern, range: range)
            .filter { $0.1 == syntaxKinds }
            .map { $0.0 }
    }

    internal func rangesAndTokens(matching pattern: String,
                                  range: NSRange? = nil) -> [(NSRange, [SyntaxToken])] {
        let contents = self.contents.bridge()
        let range = range ?? NSRange(location: 0, length: contents.length)
        let syntax = syntaxMap
        return regex(pattern).matches(in: self.contents, options: [], range: range).map { match in
            let matchByteRange = contents.NSRangeToByteRange(start: match.range.location,
                                                             length: match.range.length) ?? match.range
            let tokensInRange = syntax.tokens(inByteRange: matchByteRange)
            return (match.range, tokensInRange)
        }
    }

    internal func match(pattern: String, range: NSRange? = nil) -> [(NSRange, [SyntaxKind])] {
        return rangesAndTokens(matching: pattern, range: range).map { range, tokens in
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
        guard !sourcekitdFailed, let tokens = syntaxTokensByLine() else {
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
    internal func match(pattern: String,
                        excludingSyntaxKinds syntaxKinds: [SyntaxKind],
                        range: NSRange? = nil) -> [NSRange] {
        return match(pattern: pattern, range: range)
            .filter { $0.1.filter(syntaxKinds.contains).isEmpty }
            .map { $0.0 }
    }

    internal typealias MatchMapping = (NSTextCheckingResult) -> NSRange

    internal func match(pattern: String,
                        range: NSRange? = nil,
                        excludingSyntaxKinds: [SyntaxKind],
                        excludingPattern: String,
                        exclusionMapping: MatchMapping = { $0.range }) -> [NSRange] {
        let matches = match(pattern: pattern, excludingSyntaxKinds: excludingSyntaxKinds)
        if matches.isEmpty {
            return []
        }
        let range = range ?? NSRange(location: 0, length: contents.bridge().length)
        let exclusionRanges = regex(excludingPattern).matches(in: contents, options: [],
                                                              range: range).map(exclusionMapping)
        return matches.filter { !$0.intersects(exclusionRanges) }
    }

    internal func validateVariableName(_ dictionary: [String: SourceKitRepresentable],
                                       kind: SwiftDeclarationKind) -> (name: String, offset: Int)? {
        guard let name = dictionary.name,
            let offset = dictionary.offset,
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

    internal func ruleEnabled(violatingRanges: [NSRange], for rule: Rule) -> [NSRange] {
        let fileRegions = regions()
        if fileRegions.isEmpty { return violatingRanges }
        let violatingRanges = violatingRanges.filter { range in
            let region = fileRegions.first(where: {
                $0.contains(Location(file: self, characterOffset: range.location))
            })
            return region?.isRuleEnabled(rule) ?? true
        }
        return violatingRanges
    }

    fileprivate func numberOfCommentAndWhitespaceOnlyLines(startLine: Int, endLine: Int) -> Int {
        let commentKinds = Set(SyntaxKind.commentKinds())
        return syntaxKindsByLines[startLine...endLine].filter { kinds in
            kinds.filter { !commentKinds.contains($0) }.isEmpty
        }.count
    }

    internal func exceedsLineCountExcludingCommentsAndWhitespace(_ start: Int, _ end: Int,
                                                                 _ limit: Int) -> (Bool, Int) {
        guard end - start > limit else {
            return (false, end - start)
        }

        let count = end - start - numberOfCommentAndWhitespaceOnlyLines(startLine: start, endLine: end)
        return (count > limit, count)
    }

    internal func correct<R: Rule>(legacyRule: R, patterns: [String: String]) -> [Correction] {
        typealias RangePatternTemplate = (NSRange, String, String)
        let matches: [RangePatternTemplate]
        matches = patterns.flatMap({ pattern, template -> [RangePatternTemplate] in
            return match(pattern: pattern).filter { range, kinds in
                return kinds.first == .identifier &&
                    !ruleEnabled(violatingRanges: [range], for: legacyRule).isEmpty
            }.map { ($0.0, pattern, template) }
        }).sorted { $0.0.location > $1.0.location } // reversed

        guard !matches.isEmpty else { return [] }

        let description = type(of: legacyRule).description
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
