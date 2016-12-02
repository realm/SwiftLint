//
//  NSRegularExpression+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

private var regexCache = [String: NSRegularExpression]()

extension NSRegularExpression {
    internal static func cached(pattern: String) throws -> NSRegularExpression {
        if let result = regexCache[pattern] {
            return result
        }

        let result = try NSRegularExpression(pattern: pattern,
            options: [.anchorsMatchLines, .dotMatchesLineSeparators])
        regexCache[pattern] = result
        return result
    }

    internal static func forcePattern(_ pattern: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        return try! .cached(pattern: pattern)
    }
}
