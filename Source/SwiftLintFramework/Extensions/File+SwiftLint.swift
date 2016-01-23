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
    return try! NSRegularExpression(pattern: pattern,
                                    options: [.AnchorsMatchLines, .DotMatchesLineSeparators])
}

extension File {
    public func regions() -> [Region] {
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

    public func matchPattern(pattern: String,
                             withSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        return matchPattern(pattern).filter { _, kindsInRange in
            return kindsInRange.count == syntaxKinds.count &&
                zip(kindsInRange, syntaxKinds).filter({ $0.0 != $0.1 }).isEmpty
        }.map { $0.0 }
    }

    public func matchPattern(pattern: String) -> [(NSRange, [SyntaxKind])] {
        let contents = self.contents as NSString
        let range = NSRange(location: 0, length: contents.length)
        let syntax = syntaxMap
        let matches = regex(pattern).matchesInString(self.contents, options: [], range: range)
        return matches.map { match in
            let matchByteRange = contents.NSRangeToByteRange(start: match.range.location,
                length: match.range.length) ?? match.range
            let kindsInRange = syntax.tokens.filter { token in
                let tokenByteRange = NSRange(location: token.offset, length: token.length)
                return NSIntersectionRange(matchByteRange, tokenByteRange).length > 0
            }.map({ $0.type }).flatMap(SyntaxKind.init)
            return (match.range, kindsInRange)
        }
    }

    internal func syntaxKindsByLine(startLine: Int? = nil,
                                    endLine: Int? = nil) -> [(Int, [SyntaxKind])] {
        let contents = self.contents as NSString
        let kindsWithLines = syntaxMap.tokens.map { token -> (Int, SyntaxToken) in
            let tokenLine = contents.lineAndCharacterForByteOffset(token.offset)
            return (tokenLine!.line, token)
        }.filter { line, token in
            return line >= (startLine ?? 0) && line <= (endLine ?? Int.max)
        }.map { (line, token) -> (Int, SyntaxKind) in
            return (line, SyntaxKind(rawValue: token.type)!)
        }
        var results = [Int: [SyntaxKind]]()
        for kindAndLine in kindsWithLines {
            results[kindAndLine.0] = (results[kindAndLine.0] ?? []) + [kindAndLine.1]
        }

        for line in lines
            where line.index >= (startLine ?? 0) && line.index <= (endLine ?? Int.max) {
            results[line.index] = results[line.index] ?? []
        }

        return Array(zip(results.keys, results.values))
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
        return matchPattern(pattern).filter {
            $0.1.filter(syntaxKinds.contains).isEmpty
        }.map { $0.0 }
    }

    public func validateVariableName(dictionary: [String: SourceKitRepresentable],
                                     kind: SwiftDeclarationKind) -> (name: String, offset: Int)? {
        guard let name = dictionary["key.name"] as? String,
            offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) where
            SwiftDeclarationKind.variableKinds().contains(kind) && !name.hasPrefix("$") else {
                return nil
        }
        return (name.nameStrippingLeadingUnderscoreIfPrivate(dictionary), offset)
    }

    public func append(string: String) {
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

    public func write(string: String) {
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

        return syntaxKindsByLines.filter { line, kinds -> Bool in
            guard line >= startLine && line <= endLine else {
                return false
            }

            // if the line has only whitespace, `kinds` will be an empty array
            return kinds.filter { !commentKinds.contains($0) }.isEmpty
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
