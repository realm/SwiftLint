//
//  NSRegularExpression+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

#if os(Linux)
public typealias NSRegularExpression = RegularExpression
public typealias NSTextCheckingResult = TextCheckingResult
#endif

private var regexCache = [RegexCacheKey: NSRegularExpression]()

private struct RegexCacheKey: Hashable {
    let pattern: String
    let options: NSRegularExpression.Options

    var hashValue: Int {
        return pattern.hashValue ^ options.rawValue.hashValue
    }

    static func == (lhs: RegexCacheKey, rhs: RegexCacheKey) -> Bool {
        return lhs.options == rhs.options && lhs.pattern == rhs.pattern
    }
}

extension NSRegularExpression {
    internal static func cached(pattern: String, options: Options? = nil) throws -> NSRegularExpression {
        let options = options ?? [.anchorsMatchLines, .dotMatchesLineSeparators]
        let key = RegexCacheKey(pattern: pattern, options: options)
        if let result = regexCache[key] {
            return result
        }

        let result = try NSRegularExpression(pattern: pattern, options: options)
        regexCache[key] = result
        return result
    }
}
