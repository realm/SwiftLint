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
    internal func hasTrailingWhitespace() -> Bool {
        if isEmpty {
            return false
        }

        if let character = utf16.suffix(1).first {
            return NSCharacterSet.whitespaceCharacterSet().characterIsMember(character)
        }

        return false
    }

    internal func isUppercase() -> Bool {
        return self == uppercaseString
    }

    internal func isLowercase() -> Bool {
        return self == lowercaseString
    }

    internal func nameStrippingLeadingUnderscoreIfPrivate(dict: [String: SourceKitRepresentable]) ->
                                                        String {
        let privateACL = "source.lang.swift.accessibility.private"
        if dict["key.accessibility"] as? String == privateACL && characters.first == "_" {
            return self[startIndex.successor()..<endIndex]
        }
        return self
    }

    internal subscript (range: Range<Int>) -> String {
        let nsrange = NSRange(location: range.startIndex, length: range.endIndex - range.startIndex)
        if let indexRange = nsrangeToIndexRange(nsrange) {
            return substringWithRange(indexRange)
        }
        fatalError("invalid range")
    }

    internal func substring(from: Int, length: Int? = nil) -> String {
        if let length = length {
            return self[from..<from + length]
        }
        return substringFromIndex(startIndex.advancedBy(from, limit: endIndex))
    }

    internal func lastIndexOf(search: String) -> Int? {
        if let range = rangeOfString(search, options: [.LiteralSearch, .BackwardsSearch]) {
            return startIndex.distanceTo(range.startIndex)
        }
        return nil
    }

    internal func nsrangeToIndexRange(nsrange: NSRange) -> Range<Index>? {
        guard nsrange.location != NSNotFound else {
            return nil
        }
        let from16 = utf16.startIndex.advancedBy(nsrange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsrange.length, limit: utf16.endIndex)
        if let from = Index(from16, within: self), to = Index(to16, within: self) {
            return from..<to
        }
        return nil
    }

    public func absolutePathStandardized() -> String {
        return (self.absolutePathRepresentation() as NSString).stringByStandardizingPath
    }
}
