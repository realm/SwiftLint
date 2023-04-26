import Dispatch

public extension Array where Element: Equatable {
    /// The elements in this array, discarding duplicates after the first one.
    /// Order-preserving.
    var unique: [Element] {
        var uniqueValues = [Element]()
        for item in self where !uniqueValues.contains(item) {
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}

public extension Array where Element: Hashable {
    /// Produces an array containing the passed `obj` value.
    /// If `obj` is an array already, return it.
    /// If `obj` is a set, copy its elements to a new array.
    /// If `obj` is a value of type `Element`, return a single-item array containing it.
    ///
    /// - parameter obj: The input.
    ///
    /// - returns: The produced array.
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

public extension Array {
    /// Produces an array containing the passed `obj` value.
    /// If `obj` is an array already, return it.
    /// If `obj` is a value of type `Element`, return a single-item array containing it.
    ///
    /// - parameter obj: The input.
    ///
    /// - returns: The produced array.
    static func array(of obj: Any?) -> [Element]? {
        if let array = obj as? [Element] {
            return array
        } else if let obj = obj as? Element {
            return [obj]
        }
        return nil
    }

    /// Group the elements in this array into a dictionary, keyed by applying the specified `transform`.
    ///
    /// - parameter transform: The transformation function to extract an element to its group key.
    ///
    /// - returns: The elements grouped by applying the specified transformation.
    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        return Dictionary(grouping: self, by: { transform($0) })
    }

    /// Returns the elements failing the `belongsInSecondPartition` test, followed by the elements passing the
    /// `belongsInSecondPartition` test.
    ///
    /// - parameter belongsInSecondPartition: The test function to determine if the element should be in the second
    ///                                       partition.
    ///
    /// - returns: The elements failing the `belongsInSecondPartition` test, followed by the elements passing the
    ///            `belongsInSecondPartition` test.
    func partitioned(by belongsInSecondPartition: (Element) throws -> Bool) rethrows ->
        (first: ArraySlice<Element>, second: ArraySlice<Element>) {
            var copy = self
            let pivot = try copy.partition(by: belongsInSecondPartition)
            return (copy[0..<pivot], copy[pivot..<count])
    }

    /// Same as `flatMap` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element and flattening the results.
    func parallelFlatMap<T>(transform: (Element) -> [T]) -> [T] {
        return parallelMap(transform: transform).flatMap { $0 }
    }

    /// Same as `compactMap` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element and discarding the `nil` ones.
    func parallelCompactMap<T>(transform: (Element) -> T?) -> [T] {
        return parallelMap(transform: transform).compactMap { $0 }
    }

    /// Same as `map` but spreads the work in the `transform` block in parallel using GCD's `concurrentPerform`.
    ///
    /// - parameter transform: The transformation to apply to each element.
    ///
    /// - returns: The result of applying `transform` on every element.
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

public extension Collection {
    /// Whether this collection has one or more element.
    var isNotEmpty: Bool {
        return !isEmpty
    }

    /// Get the only element in the collection.
    ///
    /// If the collection is empty or contains more than one element the result will be `nil`.
    var onlyElement: Element? {
        count == 1 ? first : nil
    }
}
