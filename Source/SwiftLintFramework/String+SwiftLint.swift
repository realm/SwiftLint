//
//  String+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC

extension String {
    func hasTrailingWhitespace() -> Bool {
        if isEmpty {
            return false
        }

        if let character = utf16.suffix(1).first {
            return NSCharacterSet.whitespaceCharacterSet().characterIsMember(character)
        }

        return false
    }

    func isUppercase() -> Bool {
        return self == uppercaseString
    }

    public var chomped: String {
        return stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }

    public func nameStrippingLeadingUnderscoreIfPrivate(dict: XPCDictionary) -> String {
        let privateACL = "source.lang.swift.accessibility.private"
        if dict["key.accessibility"] as? String == privateACL && characters.first == "_" {
            return self[startIndex.successor()..<endIndex]
        }
        return self
    }

    subscript (range: Range<Int>) -> String {
        get {
            let subStart = startIndex.advancedBy(range.startIndex, limit: endIndex)
            let subEnd = subStart.advancedBy(range.endIndex - range.startIndex, limit: endIndex)
            return substringWithRange(Range(start: subStart, end: subEnd))
        }
    }

    func substring(from: Int, length: Int? = nil) -> String {
        if let length = length {
            return self[from..<from + length]
        }
        return substringFromIndex(startIndex.advancedBy(from, limit: endIndex))
    }

    public func lastIndexOf(search: String) -> Int? {
        if let range = rangeOfString(search, options: [.LiteralSearch, .BackwardsSearch]) {
            return startIndex.distanceTo(range.startIndex)
        }
        return nil
    }
}

extension NSString {
    public func lineAndCharacterForByteOffset(offset: Int) -> (line: Int, character: Int)? {
        return byteRangeToNSRange(start: offset, length: 0).flatMap { range in
            var numberOfLines = 0, index = 0, lineRangeStart = 0, previousIndex = 0
            while index < length {
                numberOfLines++
                if index > range.location {
                    break
                }
                lineRangeStart = numberOfLines
                previousIndex = index
                index = NSMaxRange(lineRangeForRange(NSRange(location: index, length: 1)))
            }
            return (lineRangeStart, range.location - previousIndex + 1)
        }
    }
}
