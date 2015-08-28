//
//  File+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

typealias Line = (index: Int, content: String)

extension File {
    public func matchPattern(pattern: String,
        withSyntaxKinds syntaxKinds: [SyntaxKind]) -> [NSRange] {
        return matchPattern(pattern).filter { _, kindsInRange in
            return kindsInRange.count == syntaxKinds.count &&
                zip(kindsInRange, syntaxKinds).filter({ $0.0 != $0.1 }).count == 0
        }.map { $0.0 }
    }

    public func matchPattern(pattern: String) -> [(NSRange, [SyntaxKind])] {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntax = syntaxMap
        let matches = regex.matchesInString(contents, options: [], range: range)
        return matches.map { match in
            let tokensInRange = syntax.tokens.filter {
                NSLocationInRange($0.offset, match.range)
            }
            let kindsInRange = tokensInRange.flatMap {
                SyntaxKind(rawValue: $0.type)
            }
            return (match.range, kindsInRange)
        }
    }
}
