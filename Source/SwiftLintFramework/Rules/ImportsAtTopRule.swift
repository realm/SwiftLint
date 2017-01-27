//
//  ImportsAtTopRule.swift
//  SwiftLint
//
//  Created by Miguel Revetria on 8/2/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ImportsAtTopRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() { }

    public static let description = RuleDescription(
        identifier: "imports_at_top",
        name: "Imports at top",
        description: "Imports should be placed at top of the file.",
        nonTriggeringExamples: [
            "import AAA\n",
            "import AAA\nstruct Struct { }",
            "import AAA\n@testable import BBB\ntypealias AAAA = BBB"
        ],
        triggeringExamples: [
            "struct Struct { }\n↓import AAA",
            "extension File { }\n↓import AAA\n",
            "import AAA\nvar aaa = 1\n↓import BBB"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let imports = file.parseImports()
        let contents = file.contents.bridge()
        let importByteRanges = imports.map { $0.byteRange }
        let commentsTokens = [
            SyntaxKind.comment,
            SyntaxKind.commentMark,
            SyntaxKind.commentURL,
            SyntaxKind.docComment,
            SyntaxKind.docCommentField
        ].map { $0.rawValue }

        return imports.flatMap { imp in
            let range = NSRange(location: 0, length: imp.byteRange.location)

            let nextTokens = file.syntaxMap.tokens(inByteRange: range)
                .filter { token in
                    // Remove all tokens that belong to some of the file's imports
                    return !commentsTokens.contains(token.type) && nil == importByteRanges.first { byteRange in
                        return token.offset >= byteRange.location &&
                            (token.offset + token.length) <= NSMaxRange(byteRange)
                    }
                }

            return nextTokens
                .first { token in
                    let tokenValue = contents.substringWithByteRange(start: token.offset, length: token.length)
                    return token.type == SyntaxKind.keyword.rawValue &&
                        tokenValue != "import" && tokenValue != "@testable"
                }.map { _ in
                    StyleViolation(
                        ruleDescription: type(of: self).description,
                        severity: configuration.severity,
                        location: Location(file: file, characterOffset: imp.range.location)
                    )
                }
        }
    }

}
