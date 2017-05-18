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
        description: "Files should have consistent header comments.",
        nonTriggeringExamples: [
            "let foo = \"Copyright\"",
            "let foo = 2 // Copyright",
            "let foo = 2\n // Copyright"
        ],
        triggeringExamples: [
            "// ↓Copyright\n",
            "//\n// ↓Copyright",
            "//\n" +
            "//  FileHeaderRule.swift\n" +
            "//  SwiftLint\n" +
            "//\n" +
            "//  Created by Marcelo Fabri on 27/11/16.\n" +
            "//  ↓Copyright © 2016 Realm. All rights reserved.\n" +
            "//"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
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

        // first location will be used for region purposes, second one will be the one reported
        var violationsOffsets = [(Int, Int)]()
        if let firstToken = firstToken, let lastToken = lastToken {
            let start = firstToken.offset
            let length = lastToken.offset + lastToken.length - firstToken.offset
            guard let range = file.contents.bridge()
                .byteRangeToNSRange(start: start, length: length) else {
                return []
            }

            if let regex = configuration.forbiddenRegex {
                let matches = regex.matches(in: file.contents, options: [], range: range)
                if let firstMatch = matches.first {
                    let location = firstMatch.range.location + firstMatch.range.length - 1
                    violationsOffsets.append((location, firstMatch.range.location))
                }
            }

            if let regex = configuration.requiredRegex {
                let matches = regex.matches(in: file.contents, options: [], range: range)
                if matches.isEmpty {
                    let location = range.location + range.length - 1
                    violationsOffsets.append((location, start))
                }
            }
        } else if configuration.requiredRegex != nil {
            return [
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file.path, line: 1)
                )
            ]
        }

        return violations(fromOffsets: violationsOffsets, file: file)
    }

    private func violations(fromOffsets violationsOffsets: [(Int, Int)], file: File) -> [StyleViolation] {
        let locations: [Int] = violationsOffsets.flatMap {
            let ranges = [NSRange(location: $0.0, length: 0)]
            guard !file.ruleEnabled(violatingRanges: ranges, for: self).isEmpty else {
                return nil
            }

            return $0.1
        }

        return locations.map {
            StyleViolation(
                ruleDescription: type(of: self).description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file, characterOffset: $0)
            )
        }
    }
}
