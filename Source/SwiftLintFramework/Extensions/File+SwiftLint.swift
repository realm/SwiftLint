//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC

internal func regex(pattern: String) -> NSRegularExpression {
    // all patterns used for regular expressions in SwiftLint are string literals which have been
    // confirmed to work, so it's ok to force-try here.

    // swiftlint:disable:next force_try
    return try! NSRegularExpression(pattern: pattern, options: [.AnchorsMatchLines])
}

extension File {
    public func regions() -> [Region] {
        let contents = self.contents as NSString
        let commands = matchPattern("swiftlint:(enable|disable)(:previous|:this|:next)?\\ [^\\s]+",
            withSyntaxKinds: [.Comment]).flatMap { range in
                return Command(string: contents, range: range)
        }.flatMap { command in
            return command.expand()
        }
        let totalNumberOfLines = lines.count
        let numberOfCharactersInLastLine = lines.last?.content.characters.count
        var regions = [Region]()
        var disabledRules = Set<String>()
        let commandPairs = zip(commands, Array(commands.dropFirst().map(Optional.init)) + [nil])
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

    public func validateVariableName(dictionary: XPCDictionary, kind: SwiftDeclarationKind) ->
                                     (name: String, offset: Int)? {
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
}
