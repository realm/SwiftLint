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
    public func matchPattern(pattern: String, withSyntaxKinds syntaxKinds: [SyntaxKind] = []) ->
        [NSRange] {
        return flatMap(NSRegularExpression(pattern: pattern, options: nil, error: nil)) { regex in
            let range = NSRange(location: 0, length: count(self.contents.utf16))
            let syntax = self.syntaxMap
            let matches = regex.matchesInString(self.contents, options: nil, range: range)
            return map(matches as? [NSTextCheckingResult]) { matches in
                return compact(matches.map { match in
                    let tokensInRange = syntax.tokens.filter {
                        NSLocationInRange($0.offset, match.range)
                    }
                    let kindsInRange = compact(map(tokensInRange) {
                        SyntaxKind(rawValue: $0.type)
                    })
                    if kindsInRange.count != syntaxKinds.count {
                        return nil
                    }
                    for (index, kind) in enumerate(syntaxKinds) {
                        if kind != kindsInRange[index] {
                            return nil
                        }
                    }
                    return match.range
                })
            }
        } ?? []
    }
}
