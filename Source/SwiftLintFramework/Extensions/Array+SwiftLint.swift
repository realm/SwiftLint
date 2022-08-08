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

    func group<U: Hashable>(by transform: (Element) -> U) -> [U: [Element]] {
        return Dictionary(grouping: self, by: { transform($0) })
    }

    func partitioned(by belongsInSecondPartition: (Element) throws -> Bool) rethrows ->
        (first: ArraySlice<Element>, second: ArraySlice<Element>) {
            var copy = self
            let pivot = try copy.partition(by: belongsInSecondPartition)
            return (copy[0..<pivot], copy[pivot..<count])
    }
}

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
