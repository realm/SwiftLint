//
//  Structure+SwiftLint.swift
//  SwiftLint
//
//  Created by Norio Nomura on 2/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension Structure {

    /// Returns array of tuples containing "key.kind" and "byteRange" from Structure
    /// that contains the byte offset.
    ///
    /// - Parameter byteOffset: Int
    // swiftlint:disable:next valid_docs
    internal func kindsFor(byteOffset: Int) -> [(kind: String, byteRange: NSRange)] {
        var results = [(kind: String, byteRange: NSRange)]()

        func parse(dictionary: [String : SourceKitRepresentable]) {
            guard let
                offset = (dictionary["key.offset"] as? Int64).map({ Int($0) }),
                byteRange = (dictionary["key.length"] as? Int64).map({ Int($0) })
                    .map({ NSRange(location: offset, length: $0) })
                where NSLocationInRange(byteOffset, byteRange) else {
                    return
            }
            if let kind = dictionary["key.kind"] as? String {
                results.append((kind: kind, byteRange: byteRange))
            }
            if let subStructure = dictionary["key.substructure"] as? [SourceKitRepresentable] {
                for case let dictionary as [String : SourceKitRepresentable] in subStructure {
                    parse(dictionary)
                }
            }
        }
        parse(dictionary)
        return results
    }
}
