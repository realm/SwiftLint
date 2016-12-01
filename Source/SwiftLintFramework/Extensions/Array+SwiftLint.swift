//
//  Array+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

extension Array {
    static func array(of obj: Any?) -> [Element]? {
        if let array = obj as? [Element] {
            return array
        } else if let obj = obj as? Element {
            return [obj]
        }
        return nil
    }
}

extension Array where Element: NSTextCheckingResult {
    func ranges() -> [NSRange] {
        return map { $0.range }
    }
}

extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            if !uniqueValues.contains(item) {
                uniqueValues += [item]
            }
        }
        return uniqueValues
    }
}

extension Array {
    // swiftlint:disable:next line_length
    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        var dictionary: [U: [Element]] = [:]
        for element in self {
            let key = transform(element)
            if case nil = dictionary[key]?.append(element) { dictionary[key] = [element] }
        }
        return dictionary
    }
}
