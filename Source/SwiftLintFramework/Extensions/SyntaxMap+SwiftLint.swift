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
    internal func tokensIn(_ byteRange: NSRange) -> [SyntaxToken] {

        func intersect(_ token: SyntaxToken) -> Bool {
            return NSRange(location: token.offset, length: token.length)
                .intersectsRange(byteRange)
        }

        func notIntersect(_ token: SyntaxToken) -> Bool {
            return !intersect(token)
        }

        guard let startIndex = tokens.index(where: intersect) else {
            return []
        }
        let tokensBeginningIntersect = tokens.lazy.suffix(from: startIndex)
        if let endIndex = tokensBeginningIntersect.index(where: notIntersect) {
            return Array(tokensBeginningIntersect.prefix(upTo: endIndex))
        }
        return Array(tokensBeginningIntersect)
    }
}
