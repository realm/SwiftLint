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
            return CharacterSet.whitespaces.contains(UnicodeScalar(character)!)
        }

        return false
    }

    internal func isUppercase() -> Bool {
        return self == uppercased()
    }

    internal func isLowercase() -> Bool {
        return self == lowercased()
    }

    internal func nameStrippingLeadingUnderscoreIfPrivate(_ dict: [String: SourceKitRepresentable]) ->
                                                          String {
        let privateACL = "source.lang.swift.accessibility.private"
        if dict["key.accessibility"] as? String == privateACL && characters.first == "_" {
            return substring(from: index(after: startIndex))
        }
        return self
    }

    internal subscript (range: Range<Int>) -> String {
        let nsrange = NSRange(location: range.lowerBound, length: range.upperBound - range.lowerBound)
        if let indexRange = nsrangeToIndexRange(nsrange) {
            return self.substring(with: indexRange)
        }
        fatalError("invalid range")
    }

    internal func substring(_ from: Int, length: Int? = nil) -> String {
        if let length = length {
            return self[from..<from + length]
        }
        return self.substring(from: characters.index(startIndex, offsetBy: from, limitedBy: endIndex)!)
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
        let from16 = utf16.index(utf16.startIndex,
                                 offsetBy: nsrange.location,
                                 limitedBy: utf16.endIndex) ?? utf16.endIndex
        let to16 = utf16.index(from16,
                               offsetBy: nsrange.length,
                               limitedBy: utf16.endIndex) ?? utf16.endIndex
        if let from = Index(from16, within: self), let to = Index(to16, within: self) {
            return from..<to
        }
        return nil
    }

    public func absolutePathStandardized() -> String {
        return (self.absolutePathRepresentation() as NSString).standardizingPath
    }
}
