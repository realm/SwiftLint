//
//  NSRegularExpression+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public extension NSRegularExpression {
    public convenience init(pattern: String) throws {
        try self.init(pattern: pattern,
            options: [.AnchorsMatchLines, .DotMatchesLineSeparators])
    }
    public static func forcePattern(pattern: String) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(pattern: pattern)
    }
}
