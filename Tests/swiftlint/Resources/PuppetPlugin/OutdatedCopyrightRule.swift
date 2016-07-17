//
//  OutdatedCopyrightRule.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//
import Foundation
import SwiftLintFramework
import SourceKittenFramework

public struct OutdatedCopyrightRuleConfiguration: RuleConfiguration, Equatable {
    public let severity = SeverityConfiguration(.Warning)
    public var language: String

    public init(language: String = "en") {
        self.language = language
    }

    public var consoleDescription: String {
        return "(language) \(language)"
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configurationDict = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }
        if let value = configurationDict["language"] as? String {
            self.language = value
        }
    }
}

public func == (lhs: OutdatedCopyrightRuleConfiguration,
                rhs: OutdatedCopyrightRuleConfiguration) -> Bool {
    return lhs.language == rhs.language
}

public class OutdatedCopyrightRule: ASTRule, ConfigurationProviderRule {
    public var configuration = OutdatedCopyrightRuleConfiguration(language: "en")

    public required init() {}

    public static let description = RuleDescription(
        identifier: "outdated_copyright",
        name: "OutdatedCopyright",
        description: "Warn about outdated copyrights",
        nonTriggeringExamples: [
            "//  Copyright © \(OutdatedCopyrightRule.currentYear()) Realm.",
            "//  Copyright © 1996-\(OutdatedCopyrightRule.currentYear()) Realm."
        ],
        triggeringExamples: [
            "//  Copyright © ↓2015 Realm.",
            "//  Copyright © 1996-↓2001 Realm."
        ])

    public func validateFile(file: File, kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let commentTokens = self.commentTokens(file.syntaxMap.tokens)
        let contents = file.content(for: commentTokens)
        return getViolations(for: file, contents: contents)
    }

    // swiftlint:disable:next line_length
    private func getViolations(for file: File, contents: [(token: SyntaxToken, content: String)]) -> [StyleViolation] {
        let pattern = "copyright.+(\\d{4})\\s*(?:\\-\\s*(\\d{4}))?"
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: pattern, options: [.CaseInsensitive])
        var violations: [StyleViolation] = []

        let currentYear = self.dynamicType.currentYear()
        for (token, content) in contents {
            let nsString = content as NSString
            let range = NSRange(location: 0, length: nsString.length)
            let matches = regex.matchesInString(content, options: [], range: range)
            for match in matches {
                if match.numberOfRanges != 3 {
                    continue
                }
                let range: NSRange
                if match.rangeAtIndex(2).location != NSNotFound {
                    range = match.rangeAtIndex(2)
                } else if match.rangeAtIndex(1).location != NSNotFound {
                    range = match.rangeAtIndex(1)
                } else {
                    continue
                }
                let year = nsString.substringWithRange(range)
                if year != currentYear {
                    let offset = token.offset + range.location
                    let location = Location(file: file, characterOffset: offset)
                    let violation = StyleViolation(ruleDescription: self.dynamicType.description,
                                                   severity: configuration.severity.severity,
                                                   location: location)
                    violations.append(violation)
                }

            }
        }
        return violations
    }

    private static func currentYear() -> String {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        let year = calendar.component(.Year, fromDate: NSDate())
        return "\(year)"
    }

    private func commentTokens(tokens: [SyntaxToken]) -> [SyntaxToken] {
        let commentTypes = [SyntaxKind.Comment, .CommentMark,
                            .CommentURL, .DocComment, .DocCommentField]
        let rawCommentTypes = Set(commentTypes.map { $0.rawValue })
        return tokens.filter { rawCommentTypes.contains($0.type) }

    }
}

private extension File {
    func content(for tokens: [SyntaxToken]) -> [(token: SyntaxToken, content: String)] {
        return tokens.flatMap { token in
//            return (token: token, comment: ¿contents.commentBodyX(¿nsRange))
            let nsRange = contents.byteRangeToNSRange(start: token.offset, length: token.length)
            return nsRange.flatMap { nsRange in
                contents.commentBodyX(nsRange).flatMap { comment in
                    (token: token, comment: comment)
                }
            }
        }
    }
}

private extension String {
    func commentBodyX(range: NSRange) -> String? {
        let nsString = self as NSString
        let substring = nsString
            .substringWithRange(range)
            .stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
        let pattern = "//\\s*(.+)"
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(location: 0, length: substring.characters.count)
        let matches = regex.matchesInString(substring, options: [], range: nsRange)
        guard let match = matches.first
            where matches.count == 1
               && match.numberOfRanges == 2 else {
            return nil
        }
        let matchRange = match.rangeAtIndex(1)
        if matchRange.location == NSNotFound {
            return nil
        }
        return (substring as NSString).substringWithRange(matchRange)
    }

    func range(for range: NSRange) -> Range<Index> {
        let startIndex = self.startIndex.advancedBy(range.location)
        let endIndex = self.startIndex.advancedBy(range.location + range.length)
        return startIndex..<endIndex
    }
}
