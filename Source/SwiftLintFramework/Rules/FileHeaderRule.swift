//
//  FileHeaderRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 27/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct FileHeaderRule: ConfigurationProviderRule, OptInRule {
    public var configuration = FileHeaderConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "file_header",
        name: "File Header",
        description: "Files should not have header comments.",
        nonTriggeringExamples: [
            "let foo = \"Copyright\"",
            "let foo = 2 // Copyright",
            "let foo = 2\n // Copyright"
        ],
        triggeringExamples: [
            "// Copyright\n",
            "//\n// Copyright",
            "//\n" +
            "//  FileHeaderRule.swift\n" +
            "//  SwiftLint\n" +
            "//\n" +
            "//  Created by Marcelo Fabri on 27/11/16.\n" +
            "//  Copyright © 2016 Realm. All rights reserved.\n" +
            "//"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        var firstToken: SyntaxToken?
        var lastToken: SyntaxToken?

        for token in file.syntaxTokensByLines.joined() {
            guard let kind = SyntaxKind(rawValue: token.type), kind.isCommentLike else {
                // found a token that is not a comment, which means it's not the top of the file
                // so we can just skip the remaining tokens
                break
            }

            if firstToken == nil {
                firstToken = token
            }
            lastToken = token
        }

        var violationsOffsets: [Int] = []
        if let firstToken = firstToken, let lastToken = lastToken {
            let start = firstToken.offset
            let length = lastToken.offset + lastToken.length - firstToken.offset
            guard let range = file.contents.byteRangeToNSRange(start: start, length: length) else {
                return []
            }

            if let regex = configuration.forbiddenRegex {
                let matches = regex.matches(in: file.contents, options: [], range: range)
                if let firstMatch = matches.first {
                    let location = firstMatch.range.location + firstMatch.range.length - 1
                    violationsOffsets.append(location)
                }
            }

            if let regex = configuration.requiredRegex {
                let matches = regex.matches(in: file.contents, options: [], range: range)
                if matches.isEmpty {
                    let location = range.location + range.length - 1
                    violationsOffsets.append(location)
                }
            }
        } else if configuration.requiredRegex != nil {
            return [
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file.path)
                )
            ]
        }

        let ranges = violationsOffsets.map { NSRange(location: $0, length: 0) }
        return file.ruleEnabledViolatingRanges(ranges, forRule: self).map {
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file, characterOffset: $0.location)
            )
        }
    }
}
