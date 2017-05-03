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
    /// that contains the byte offset. Returns all kinds if no parameter specified.
    ///
    /// - Parameter byteOffset: Int?
    internal func kinds(forByteOffset byteOffset: Int? = nil) -> [(kind: String, byteRange: NSRange)] {
        var results = [(kind: String, byteRange: NSRange)]()

        func parse(_ dictionary: [String: SourceKitRepresentable]) {
            guard let offset = dictionary.offset,
                let byteRange = dictionary.length.map({ NSRange(location: offset, length: $0) }) else {
                    return
            }
            if let byteOffset = byteOffset, !NSLocationInRange(byteOffset, byteRange) {
                return
            }
            if let kind = dictionary.kind {
                results.append((kind: kind, byteRange: byteRange))
            }
            dictionary.substructure.forEach(parse)
        }
        parse(dictionary)
        return results
    }
}
