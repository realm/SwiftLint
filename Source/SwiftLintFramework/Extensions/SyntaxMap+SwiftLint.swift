//
//  SyntaxMap+SwiftLint.swift
//  SwiftLint
//
//  Created by Norio Nomura on 2/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension SyntaxMap {
    /// Returns array of SyntaxTokens intersecting with byte range
    ///
    /// - Parameter byteRange: byte based NSRange
    internal func tokensIn(byteRange: NSRange) -> [SyntaxToken] {

        func intersect(token: SyntaxToken) -> Bool {
            return NSRange(location: token.offset, length: token.length)
                .intersectsRange(byteRange)
        }

        func notIntersect(token: SyntaxToken) -> Bool {
            return !intersect(token)
        }

        guard let startIndex = tokens.indexOf(intersect) else {
            return []
        }
        let tokensBeginningIntersect = tokens.lazy.suffixFrom(startIndex)
        if let endIndex = tokensBeginningIntersect.indexOf(notIntersect) {
            return Array(tokensBeginningIntersect.prefixUpTo(endIndex))
        }
        return Array(tokensBeginningIntersect)
    }
}
