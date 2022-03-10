import Dispatch
import Foundation

extension Array where Element: NSTextCheckingResult {
    @inlinable
    func ranges() -> [NSRange] {
        return map { $0.range }
    }
}

extension Array where Element: Equatable {
    @inlinable var unique: [Element] {
        var uniqueValues = [Element]()
        for item in self where !uniqueValues.contains(item) {
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}

extension Array where Element: Hashable {
    static func array(of obj: Any?) -> [Element]? {
        if let array = obj as? [Element] {
            return array
        } else if let set = obj as? Set<Element> {
            return Array(set)
        } else if let obj = obj as? Element {
            return [obj]
        }
        return nil
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

    @inlinable
    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        return Dictionary(grouping: self, by: { transform($0) })
    }

    @inlinable
    func partitioned(by belongsInSecondPartition: (Element) throws -> Bool) rethrows ->
        (first: ArraySlice<Element>, second: ArraySlice<Element>) {
            var copy = self
            let pivot = try copy.partition(by: belongsInSecondPartition)
            return (copy[0..<pivot], copy[pivot..<count])
    }

    @inlinable
    func parallelFlatMap<T>(transform: (Element) -> [T]) -> [T] {
        return parallelMap(transform: transform).flatMap { $0 }
    }

    @inlinable
    func parallelCompactMap<T>(transform: (Element) -> T?) -> [T] {
        return parallelMap(transform: transform).compactMap { $0 }
    }

    @inlinable
    func parallelMap<T>(transform: (Element) -> T) -> [T] {
        var result = ContiguousArray<T?>(repeating: nil, count: count)
        return result.withUnsafeMutableBufferPointer { buffer in
            DispatchQueue.concurrentPerform(iterations: buffer.count) { idx in
                buffer[idx] = transform(self[idx])
            }
            return buffer.map { $0! }
        }
    }
}

extension Collection {
    @inlinable var isNotEmpty: Bool {
        return !isEmpty
    }
}
