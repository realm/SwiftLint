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
    public func matchPattern(pattern: String, withSyntaxKinds syntaxKinds: [SyntaxKind]) ->
        [NSRange] {
        return matchPattern(pattern).filter { _, kindsInRange in
            return kindsInRange.count == syntaxKinds.count &&
                filter(zip(kindsInRange, syntaxKinds), { $0.0 != $0.1 }).count == 0
        }.map { $0.0 }
    }

    public func matchPattern(pattern: String) -> [(NSRange, [SyntaxKind])] {
        return flatMap(NSRegularExpression(pattern: pattern, options: nil, error: nil)) { regex in
            let range = NSRange(location: 0, length: count(contents.utf16))
            let syntax = syntaxMap
            let matches = regex.matchesInString(contents, options: nil, range: range)
            return map(matches as? [NSTextCheckingResult]) { matches in
                return matches.map { match in
                    let tokensInRange = syntax.tokens.filter {
                        NSLocationInRange($0.offset, match.range)
                    }
                    let kindsInRange = compact(map(tokensInRange) {
                        SyntaxKind(rawValue: $0.type)
                    })
                    return (match.range, kindsInRange)
                }
            }
        } ?? []
    }
}
