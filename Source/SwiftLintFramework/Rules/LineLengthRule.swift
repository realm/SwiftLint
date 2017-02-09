//
//  LineLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LineLengthRule: ConfigurationProviderRule {
    public var configuration = LineLengthConfiguration(warning: 120, error: 200)

    public init() {}

    private let commentKinds = Set(SyntaxKind.commentKinds())
    private let nonCommentKinds = Set(SyntaxKind.allKinds()).subtracting(SyntaxKind.commentKinds())
    private let functionKinds = Set(SwiftDeclarationKind.functionKinds())

    public static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Lines should not span too many characters.",
        nonTriggeringExamples: [
            String(repeating: "/", count: 120) + "\n",
            String(repeating: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)", count: 120) + "\n",
            String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 120) + "\n"
        ],
        triggeringExamples: [
            String(repeating: "/", count: 121) + "\n",
            String(repeating: "#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)", count: 121) + "\n",
            String(repeating: "#imageLiteral(resourceName: \"image.jpg\")", count: 121) + "\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let minValue = configuration.params.map({ $0.value }).min() ?? .max
        let swiftDeclarationKindsByLine = file.swiftDeclarationKindsByLine() ?? []
        let syntaxKindsByLine = file.syntaxKindsByLine() ?? []

        return file.lines.flatMap { line in
            // `line.content.characters.count` <= `line.range.length` is true.
            // So, `check line.range.length` is larger than minimum parameter value.
            // for avoiding using heavy `line.content.characters.count`.
            if line.range.length < minValue {
                return nil
            }

            if configuration.ignoresFunctionDeclarations &&
                lineHasKinds(line: line,
                             kinds: functionKinds,
                             kindsByLine: swiftDeclarationKindsByLine) {
                return nil
            }

            if configuration.ignoresComments &&
                lineHasKinds(line: line,
                             kinds: commentKinds,
                             kindsByLine: syntaxKindsByLine) &&
                !lineHasKinds(line: line,
                              kinds: nonCommentKinds,
                              kindsByLine: syntaxKindsByLine) {
                return nil
            }

            var strippedString = line.content
            if configuration.ignoresURLs {
                strippedString = strippedString.strippingURLs
            }
            strippedString = stripLiterals(fromSourceString: strippedString,
                withDelimiter: "#colorLiteral")
            strippedString = stripLiterals(fromSourceString: strippedString,
                withDelimiter: "#imageLiteral")

            let length = strippedString.characters.count

            for param in configuration.params where length > param.value {
                return StyleViolation(ruleDescription: type(of: self).description,
                    severity: param.severity,
                    location: Location(file: file.path, line: line.index),
                    reason: "Line should be \(configuration.length.warning) characters or less: " +
                        "currently \(length) characters")
            }
            return nil
        }
    }

    /// Takes a string and replaces any literals specified by the `delimiter` parameter with `#`
    ///
    /// - parameter sourceString: Original string, possibly containing literals
    /// - parameter delimiter:    Delimiter of the literal
    ///     (characters before the parentheses, e.g. `#colorLiteral`)
    ///
    /// - returns: sourceString with the given literals replaced by `#`
    private func stripLiterals(fromSourceString sourceString: String,
                               withDelimiter delimiter: String) -> String {
        var modifiedString = sourceString

        // While copy of content contains literal, replace with a single character
        while modifiedString.contains("\(delimiter)(") {
            if let rangeStart = modifiedString.range(of: "\(delimiter)("),
                let rangeEnd = modifiedString.range(of: ")",
                                                    options: .literal,
                                                    range:
                    rangeStart.lowerBound..<modifiedString.endIndex) {
                modifiedString.replaceSubrange(rangeStart.lowerBound..<rangeEnd.upperBound,
                                               with: "#")

            } else { // Should never be the case, but break to avoid accidental infinity loop
                break
            }
        }

        return modifiedString
    }

    private func lineHasKinds<Kind>(line: Line, kinds: Set<Kind>, kindsByLine: [[Kind]]) -> Bool {
        let index = line.index
        if index >= kindsByLine.count {
            return false
        }
        return !kinds.intersection(kindsByLine[index]).isEmpty
    }

}

private extension String {
    var strippingURLs: String {
        let range = NSRange(location: 0, length: bridge().length)
        // Workaround for Linux until NSDataDetector is available
        #if os(Linux)
            // Regex pattern from http://daringfireball.net/2010/07/improved_regex_for_matching_urls
            let pattern = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)" +
                "(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*" +
                "\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))"
            let urlRegex = regex(pattern)
            return urlRegex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        #else
            let types = NSTextCheckingResult.CheckingType.link.rawValue
            guard let urlDetector = try? NSDataDetector(types: types) else {
                return self
            }
            return urlDetector.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        #endif
    }
}
