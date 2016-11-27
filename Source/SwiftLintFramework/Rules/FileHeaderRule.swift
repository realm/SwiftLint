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
    public var configuration = SeverityConfiguration(.Warning)

    // swiftlint:disable:next force_try
    private static let regex = try! NSRegularExpression(pattern: "\\bCopyright\\b",
                                                        options: [.CaseInsensitive])

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
        let regex = FileHeaderRule.regex
        for token in file.syntaxTokensByLines.flatten() {
            guard let kind = SyntaxKind(rawValue: token.type) where kind.isCommentLike else {
                // found a token that is not a comment, which means it's not the top of the file
                // so we can just skip the remaining tokens
                return []
            }

            guard let range = file.contents.byteRangeToNSRange(start: token.offset,
                                                               length: token.length) else {
                continue
            }

            let matches = regex.matchesInString(file.contents, options: [], range: range)
            guard let firstMatch = matches.first else {
                continue
            }

            return [
                StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: configuration.severity,
                    location: Location(file: file, byteOffset: firstMatch.range.location))
            ]
        }

        return []
    }
}
