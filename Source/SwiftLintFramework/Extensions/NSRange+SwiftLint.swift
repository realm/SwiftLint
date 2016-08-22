//
//  NSRange+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/13/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

extension NSRange {
    func intersectsRange(range: NSRange) -> Bool {
        return NSIntersectionRange(self, range).length > 0
    }

    func intersectsRanges(ranges: [NSRange]) -> Bool {
        for range in ranges where intersectsRange(range) {
            return true
        }
        return false
    }
}
