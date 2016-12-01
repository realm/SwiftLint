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

    public func validateFile(file: File) -> [StyleViolation] {
        var firstToken: SyntaxToken?
        var lastToken: SyntaxToken?

        for token in file.syntaxTokensByLines.flatten() {
            guard let kind = SyntaxKind(rawValue: token.type) where kind.isCommentLike else {
                // found a token that is not a comment, which means it's not the top of the file
                // so we can just skip the remaining tokens
                break
            }

            if firstToken == nil {
                firstToken = token
            }
            lastToken = token
        }

        var violations: [StyleViolation] = []
        if let firstToken = firstToken, lastToken = lastToken {
            let start = firstToken.offset
            let length = lastToken.offset + lastToken.length - firstToken.offset
            guard let range = file.contents.byteRangeToNSRange(start: start, length: length) else {
                return []
            }

            if let regex = configuration.forbiddenRegex {
                let matches = regex.matchesInString(file.contents, options: [], range: range)
                if let firstMatch = matches.first {
                    let violation = StyleViolation(
                        ruleDescription: self.dynamicType.description,
                        severity: configuration.severityConfiguration.severity,
                        location: Location(file: file, byteOffset: firstMatch.range.location)
                    )
                    violations.append(violation)
                }
            }

            if let regex = configuration.requiredRegex {
                let matches = regex.matchesInString(file.contents, options: [], range: range)
                if matches.isEmpty {
                    let violation = StyleViolation(
                        ruleDescription: self.dynamicType.description,
                        severity: configuration.severityConfiguration.severity,
                        location: Location(file: file, byteOffset: start)
                    )
                    violations.append(violation)
                }
            }
        } else if configuration.requiredRegex != nil {
            return [
                StyleViolation(
                    ruleDescription: self.dynamicType.description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file.path)
                )
            ]
        }

        return violations
    }
}
