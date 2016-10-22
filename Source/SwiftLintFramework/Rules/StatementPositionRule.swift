//
//  StatementPositionRule.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/22/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct StatementPositionRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = StatementConfiguration(statementMode: .Default,
                                                     severity: SeverityConfiguration(.Warning))

    public init() {}

    public static let description = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: "Else and catch should be on the same line, one space after the previous " +
                     "declaration.",
        nonTriggeringExamples: [
            "} else if {",
            "} else {",
            "} catch {",
            "\"}else{\"",
            "struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)",
            "struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)"
        ],
        triggeringExamples: [
            "↓}else if {",
            "↓}  else {",
            "↓}\ncatch {",
            "↓}\n\t  catch {"
        ],
        corrections: [
            "}\n else {\n": "} else {\n",
            "}\n   else if {\n": "} else if {\n",
            "}\n catch {\n": "} catch {\n"
        ]
    )

    public static let uncuddledDescription = RuleDescription(
        identifier: "statement_position",
        name: "Statement Position",
        description: "Else and catch should be on the next line, with equal indentation to the " +
                     "previous declaration.",
        nonTriggeringExamples: [
            "  }\n  else if {",
            "    }\n    else {",
            "  }\n  catch {",
            "  }\n\n  catch {",
            "\n\n  }\n  catch {",
            "\"}\nelse{\"",
            "struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)",
            "struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)",
        ],
        triggeringExamples: [
            "↓  }else if {",
            "↓}\n  else {",
            "↓  }\ncatch {",
            "↓}\n\t  catch {"
        ],
        corrections: [
            "  }else if {":"  }\n  else if {",
            "}\n  else {":"}\nelse {",
            "  }\ncatch {":"  }\n  catch {",
            "}\n\t  catch {":"}\ncatch {"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        switch configuration.statementMode {
        case .Default:
            return defaultValidateFile(file)
        case .UncuddledElse:
            return uncuddledValidateFile(file)
        }
    }

    public func correctFile(file: File) -> [Correction] {
        switch configuration.statementMode {
        case .Default:
            return defaultCorrectFile(file)
        case .UncuddledElse:
            return uncuddledCorrectFile(file)
        }

    }

}

// Default Behaviors
private extension StatementPositionRule {

    // match literal '}'
    // followed by 1) nothing, 2) two+ whitespace/newlines or 3) newlines or tabs
    // followed by 'else' or 'catch' literals
    static let defaultPattern = "\\}(?:[\\s\\n\\r]{2,}|[\\n\\t\\r]+)?\\b(else|catch)\\b"

    func defaultValidateFile(file: File) -> [StyleViolation] {
        return defaultViolationRangesInFile(file,
            withPattern: self.dynamicType.defaultPattern).flatMap { range in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }

    func defaultViolationRangesInFile(file: File, withPattern pattern: String) -> [NSRange] {
        return file.matchPattern(pattern).filter { _, syntaxKinds in
            return syntaxKinds.startsWith([.Keyword])
        }.flatMap { $0.0 }
    }

    func defaultCorrectFile(file: File) -> [Correction] {
        let matches = defaultViolationRangesInFile(file,
                                                   withPattern: self.dynamicType.defaultPattern)
        guard !matches.isEmpty else { return [] }

        let regularExpression = regex(self.dynamicType.defaultPattern)
        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents
        for range in matches.reverse() {
            contents = regularExpression.stringByReplacingMatchesInString(contents,
                                                                          options: [],
                                                                          range: range,
                                                                          withTemplate: "} $1")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }
}

// Uncuddled Behaviors
private extension StatementPositionRule {
    func uncuddledValidateFile(file: File) -> [StyleViolation] {
        return uncuddledViolationRangesInFile(file).flatMap { range in
            return StyleViolation(ruleDescription: self.dynamicType.uncuddledDescription,
                severity: configuration.severity.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }

    // match literal '}'
    // preceded by whitespace (or nothing)
    // followed by 1) nothing, 2) two+ whitespace/newlines or 3) newlines or tabs
    // followed by newline and the same amount of whitespace then 'else' or 'catch' literals
    static let uncuddledPattern = "([ \t]*)\\}(\\n+)?([ \t]*)\\b(else|catch)\\b"

    static let uncuddledRegularExpression = (try? NSRegularExpression(pattern: uncuddledPattern,
        options: [])) ?? NSRegularExpression()

    static func uncuddledMatchValidator(contents: String) ->
        ((NSTextCheckingResult) -> NSTextCheckingResult?) {
        return { match in
            if match.numberOfRanges != 5 {
                return match
            }
            if match.rangeAtIndex(2).length == 0 {
                return match
            }
            let range1 = match.rangeAtIndex(1)
            let range2 = match.rangeAtIndex(3)
            let whitespace1 = contents.substring(range1.location, length: range1.length)
            let whitespace2 = contents.substring(range2.location, length: range2.length)
            if whitespace1 == whitespace2 {
                return nil
            }
            return match
        }
    }

    static func uncuddledMatchFilter(contents contents: String, syntaxMap: SyntaxMap) ->
        ((NSTextCheckingResult) -> Bool) {
        return { match in
            let range = match.range
            guard let matchRange = contents.NSRangeToByteRange(start: range.location,
                                                               length: range.length) else {
                return false
            }
            let tokens = syntaxMap.tokensIn(matchRange).flatMap { SyntaxKind(rawValue: $0.type) }
            return tokens == [.Keyword]
        }
    }

    func uncuddledViolationRangesInFile(file: File) -> [NSRange] {
        let contents = file.contents
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntaxMap = file.syntaxMap
        let matches = StatementPositionRule.uncuddledRegularExpression.matchesInString(contents,
                                                                                 options: [],
                                                                                 range: range)
        let validator = self.dynamicType.uncuddledMatchValidator(contents)
        let filterMatches = self.dynamicType.uncuddledMatchFilter(contents: contents,
                                                                  syntaxMap: syntaxMap)

        let validMatches = matches.flatMap(validator).filter(filterMatches).map({ $0.range })

        return validMatches
    }

    func uncuddledCorrectFile(file: File) -> [Correction] {
        var contents = file.contents
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntaxMap = file.syntaxMap
        let matches = StatementPositionRule.uncuddledRegularExpression.matchesInString(contents,
                                                                                       options: [],
                                                                                       range: range)
        let validator = self.dynamicType.uncuddledMatchValidator(contents)
        let filterRanges = self.dynamicType.uncuddledMatchFilter(contents: contents,
                                                                 syntaxMap: syntaxMap)

        let validMatches = matches.flatMap(validator).filter(filterRanges)

        let description = self.dynamicType.uncuddledDescription
        var corrections = [Correction]()

        for match in validMatches.reverse() {
            let range1 = match.rangeAtIndex(1)
            let nsRange2 = match.rangeAtIndex(3)
            let newlineRange = match.rangeAtIndex(2)
            let start = contents.startIndex.advancedBy(nsRange2.location)
            let end = start.advancedBy(nsRange2.length)
            let range2 = start..<end
            var whitespace = contents.substring(range1.location, length: range1.length)
            let newLines: String
            if newlineRange.location != NSNotFound {
               newLines = contents.substring(newlineRange.location, length: newlineRange.length)
            } else {
                newLines = ""
            }
            if !whitespace.hasPrefix("\n") && newLines != "\n" {
                whitespace.insert("\n", atIndex: whitespace.startIndex)
            }
            contents.replaceRange(range2, with: whitespace)
            let location = Location(file: file, characterOffset: match.range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}
