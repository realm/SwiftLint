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
    internal func kinds(forByteOffset byteOffset: Int) -> [(kind: String, byteRange: NSRange)] {
        return kinds().filter {
            NSLocationInRange(byteOffset, $0.byteRange)
        }
    }

    /// Returns complete array of tuples containing "key.kind" and "byteRange" from Structure
    internal func kinds() -> [(kind: String, byteRange: NSRange)] {
        var results = [(kind: String, byteRange: NSRange)]()
        func parse(_ dictionary: [String: SourceKitRepresentable]) {
            guard let offset = dictionary.offset,
                let length = dictionary.length else {
                    return
            }
            if let kind = dictionary.kind {
                results.append((kind: kind, byteRange: NSRange(location: offset, length: length)))
            }
            dictionary.substructure.forEach(parse)
        }
        parse(dictionary)
        return results
    }
}
