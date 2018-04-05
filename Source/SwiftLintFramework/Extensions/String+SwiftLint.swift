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

    internal func nameStrippingLeadingUnderscoreIfPrivate(_ dict: [String: SourceKitRepresentable]) -> String {
        if let aclString = dict.accessibility,
           let acl = AccessControlLevel(identifier: aclString),
            acl.isPrivate && first == "_" {
            return String(self[index(after: startIndex)...])
        }
        return self
    }

    private subscript (range: Range<Int>) -> String {
        let nsrange = NSRange(location: range.lowerBound,
                              length: range.upperBound - range.lowerBound)
        if let indexRange = nsrangeToIndexRange(nsrange) {
            return String(self[indexRange])
        }
        queuedFatalError("invalid range")
    }

    internal func substring(from: Int, length: Int? = nil) -> String {
        if let length = length {
            return self[from..<from + length]
        }
        return String(self[index(startIndex, offsetBy: from, limitedBy: endIndex)!...])
    }

    internal func lastIndex(of search: String) -> Int? {
        if let range = range(of: search, options: [.literal, .backwards]) {
            return distance(from: startIndex, to: range.lowerBound)
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

        guard let fromIndex = Index(from16, within: self),
            let toIndex = Index(to16, within: self) else {
                return nil
        }

        return fromIndex..<toIndex
    }

    public func absolutePathStandardized() -> String {
        return bridge().absolutePathRepresentation().bridge().standardizingPath
    }

    internal var isFile: Bool {
        var isDirectoryObjC: ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory: &isDirectoryObjC) {
            #if os(Linux) && (!swift(>=4.1) || (!swift(>=4.0) && swift(>=3.3)))
                return !isDirectoryObjC
            #else
                return !isDirectoryObjC.boolValue
            #endif
        }
        return false
    }
}
