//
//  String+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension String {
    internal func hasTrailingWhitespace() -> Bool {
        if isEmpty {
            return false
        }

        if let unicodescalar = unicodeScalars.last {
            return CharacterSet.whitespaces.contains(unicodescalar)
        }

        return false
    }

    internal func isUppercase() -> Bool {
        return self == uppercased()
    }

    internal func isLowercase() -> Bool {
        return self == lowercased()
    }

    internal func nameStrippingLeadingUnderscoreIfPrivate(
        _ dict: [String: SourceKitRepresentable]) -> String {
        if let aclString = dict["key.accessibility"] as? String,
           let acl = AccessControlLevel(identifier: aclString),
            acl.isPrivate && characters.first == "_" {
            return substring(from: index(after: startIndex))
        }
        return self
    }

    internal subscript (range: Range<Int>) -> String {
        let nsrange = NSRange(location: range.lowerBound,
                              length: range.upperBound - range.lowerBound)
        if let indexRange = nsrangeToIndexRange(nsrange) {
            return substring(with: indexRange)
        }
        fatalError("invalid range")
    }

    internal func substring(_ from: Int, length: Int? = nil) -> String {
        if let length = length {
            return self[from..<from + length]
        }
        let index = characters.index(startIndex, offsetBy: from, limitedBy: endIndex)!
        return substring(from: index)
    }

    internal func lastIndexOf(_ search: String) -> Int? {
        if let range = range(of: search, options: [.literal, .backwards]) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        }
        return nil
    }

    internal func nsrangeToIndexRange(_ nsrange: NSRange) -> Range<Index>? {
        guard nsrange.location != NSNotFound else {
            return nil
        }
        let from16 = utf16.index(utf16.startIndex, offsetBy: nsrange.location,
                                 limitedBy: utf16.endIndex) ?? utf16.endIndex
        let to16 = utf16.index(from16, offsetBy: nsrange.length,
                               limitedBy: utf16.endIndex) ?? utf16.endIndex
        if let from = Index(from16, within: self), let to = Index(to16, within: self) {
            return from..<to
        }
        return nil
    }

    public func absolutePathStandardized() -> String {
        return bridge().absolutePathRepresentation().bridge().standardizingPath
    }
}
