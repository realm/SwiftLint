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

    public func parallelForEach(block: @escaping ((Element) -> Void)) {
        _ = parallelMap(transform: block)
    }

    func parallelFlatMap<T>(transform: @escaping ((Element) -> [T])) -> [T] {
        return parallelMap(transform: transform).flatMap { $0 }
    }

    func parallelMap<T>(transform: @escaping ((Element) -> T)) -> [T] {
        let count = self.count
        let maxConcurrentJobs = ProcessInfo.processInfo.activeProcessorCount

        guard count > 1 && maxConcurrentJobs > 1 else {
            // skip GCD overhead if we'd only run one at a time anyway
            return map(transform)
        }

        var result = [(Int, [T])]()
        result.reserveCapacity(count)
        let group = DispatchGroup()
        let uuid = NSUUID().uuidString
        let jobCount = Int(ceil(Double(count) / Double(maxConcurrentJobs)))

        let queueLabelPrefix = "io.realm.SwiftLintFramework.map.\(uuid)"
        let resultAccumulatorQueue = DispatchQueue(label: "\(queueLabelPrefix).resultAccumulator")

        for jobIndex in stride(from: 0, to: count, by: jobCount) {
            let queue = DispatchQueue(label: "\(queueLabelPrefix).\(jobIndex / jobCount)")
            queue.async(group: group) {
                let jobElements = self[jobIndex..<Swift.min(count, jobIndex + jobCount)]
                let jobIndexAndResults = (jobIndex, jobElements.map(transform))
                resultAccumulatorQueue.sync {
                    result.append(jobIndexAndResults)
                }
            }
        }
        group.wait()
        return result.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
    }
}
