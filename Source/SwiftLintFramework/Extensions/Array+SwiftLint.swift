//
//  Array+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Dispatch
import Foundation

extension Array where Element: NSTextCheckingResult {
    func ranges() -> [NSRange] {
        return map { $0.range }
    }
}

extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues = [Element]()
        for item in self where !uniqueValues.contains(item) {
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}

extension Array {
    static func array(of obj: Any?) -> [Element]? {
        if let array = obj as? [Element] {
            return array
        } else if let obj = obj as? Element {
            return [obj]
        }
        return nil
    }

    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        return reduce([:]) { dictionary, element in
            var dictionary = dictionary
            let key = transform(element)
            dictionary[key] = (dictionary[key] ?? []) + [element]
            return dictionary
        }
    }

    func partitioned(by belongsInSecondPartition: (Element) throws -> Bool) rethrows ->
        (first: ArraySlice<Element>, second: ArraySlice<Element>) {
            var copy = self
            let pivot = try copy.partition(by: belongsInSecondPartition)
            return (copy[0..<pivot], copy[pivot..<count])
    }

    func parallelFlatMap<T>(transform: @escaping ((Element) -> [T])) -> [T] {
        return parallelMap(transform: transform).flatMap { $0 }
    }

    func parallelFlatMap<T>(transform: @escaping ((Element) -> T?)) -> [T] {
        return parallelMap(transform: transform).flatMap { $0 }
    }

    func parallelMap<T>(transform: @escaping ((Element) -> T)) -> [T] {
        var result = [(Int, T)]()
        result.reserveCapacity(count)

        let queueLabelPrefix = "io.realm.SwiftLintFramework.map.\(NSUUID().uuidString)"
        let resultAccumulatorQueue = DispatchQueue(label: "\(queueLabelPrefix).resultAccumulator")
        DispatchQueue.concurrentPerform(iterations: count) { index in
            let jobIndexAndResults = (index, transform(self[index]))
            resultAccumulatorQueue.sync {
                result.append(jobIndexAndResults)
            }
        }
        return result.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}
