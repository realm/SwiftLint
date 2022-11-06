public extension RandomAccessCollection where Index == Int {
    /// Returns the first index in which an element of the collection satisfies the given predicate.
    /// The collection assumed to be sorted. If collection is not have sorted values the result is undefined.
    ///
    /// The idea is to get first index of a function for which the given predicate evaluates to true.
    ///
    ///       let values = [1,2,3,4,5]
    ///       let idx = values.firstIndexAssumingSorted(where: { $0 > 3 })
    ///
    ///       // false, false, false, true, true
    ///       //                      ^
    ///       // therefore idx == 3
    ///
    /// - parameter predicate: A closure that takes an element as its argument
    ///                        and returns a Boolean value that indicates whether the passed element
    ///                        represents a match.
    ///
    /// - returns: The index of the first element for which `predicate` returns `true`.
    ///            If no elements in the collection satisfy the given predicate, returns `nil`.
    ///
    /// - complexity: O(log(*n*)), where *n* is the length of the collection.
    ///
    /// - throws: Rethrows errors thrown by the predicate.
    @inlinable
    func firstIndexAssumingSorted(where predicate: (Self.Element) throws -> Bool) rethrows -> Int? {
        // Predicate should divide a collection to two pairs of values
        // "bad" values for which predicate returns `false``
        // "good" values for which predicate return `true`

        // false false false false false true true true
        //                               ^
        // The idea is to get _first_ index which for which the predicate returns `true`

        let lastIndex = count

        // The index that represents where bad values start
        var badIndex = -1

        // The index that represents where good values start
        var goodIndex = lastIndex
        var midIndex = (badIndex + goodIndex) / 2

        while badIndex + 1 < goodIndex {
            if try predicate(self[midIndex]) {
                goodIndex = midIndex
            } else {
                badIndex = midIndex
            }
            midIndex = (badIndex + goodIndex) / 2
        }

        // We're out of bounds, no good items in array
        if midIndex == lastIndex {
            return nil
        }
        return goodIndex
    }
}
