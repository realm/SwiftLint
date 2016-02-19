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
        return tokens.filter { token in
            let tokenByteRange = NSRange(location: token.offset, length: token.length)
            return NSIntersectionRange(byteRange, tokenByteRange).length > 0
        }
    }
}
