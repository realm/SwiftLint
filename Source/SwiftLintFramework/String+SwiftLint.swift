//
//  String+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension String {
    func lines() -> [Line] {
        var lines = [Line]()
        var lineIndex = 1
        enumerateLines { line, stop in
            lines.append((lineIndex++, line))
        }
        return lines
    }

    func isUppercase() -> Bool {
        return self == uppercaseString
    }

    func countOfTailingCharactersInSet(characterSet: NSCharacterSet) -> Int {
        return String(reverse(self)).countOfLeadingCharactersInSet(characterSet)
    }

    public var chomped: String {
        return stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
}

extension NSString {
    public func lineAndCharacterForByteOffset(offset: Int) -> (line: Int, character: Int)? {
        return flatMap(byteRangeToNSRange(start: offset, length: 0)) { range in
            var numberOfLines = 0
            var index = 0
            var lineRangeStart = 0
            while index < length {
                numberOfLines++
                if index <= range.location {
                    lineRangeStart = numberOfLines
                    index = NSMaxRange(self.lineRangeForRange(NSRange(location: index, length: 1)))
                } else {
                    break
                }
            }
            return (lineRangeStart, 0)
        }
    }
}
