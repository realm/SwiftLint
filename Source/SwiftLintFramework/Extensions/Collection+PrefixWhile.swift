//
//  Collection+PrefixWhile.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 06/14/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

#if swift(>=3.1)
#else
    extension Collection {
        // from https://github.com/apple/swift/blob/4b0597a8/stdlib/public/core/Collection.swift#L1558
        func prefix(while predicate: (Iterator.Element) throws -> Bool) rethrows -> SubSequence {
            var end = startIndex
            while try end != endIndex && predicate(self[end]) {
                formIndex(after: &end)
            }
            return self[startIndex..<end]
        }
    }
#endif
