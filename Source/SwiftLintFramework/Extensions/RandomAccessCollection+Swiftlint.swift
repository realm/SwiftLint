internal extension RandomAccessCollection where Index == Int {
    /// Returns the first index in which an element of the collection satisfies
    /// the given predicate. The collection assumed to be sorted. If collection is not have sorted values
    /// the result is undefined
    ///
    /// The idea  is to get first index of a function where predicate starting to return true values.
    ///
    ///       let values = [1,2,3,4,5]
    ///       let idx = values.firstIndexAssumingSorted(where: { $0 > 3 })
    ///
    ///       // false, false, false, true, true
    ///       //                      ^
    ///       // therefore idx == 3
    ///
    /// - Parameter predicate: A closure that takes an element as its argument
    ///   and returns a Boolean value that indicates whether the passed element
    ///   represents a match.
    /// - Returns: The index of the first element for which `predicate` returns
    ///   `true`. If no elements in the collection satisfy the given predicate,
    ///   returns `nil`.
    ///
    /// - Complexity: O(log(*n*)), where *n* is the length of the collection.
    @inlinable
    func firstIndexAssumingSorted(where predicate: (Self.Element) throws -> Bool) rethrows -> Int? {
        // Predicate should divide a collection to two pars of vaues
        // "bad" values for which predicate returns `false``
        // "good" values for which predicate return `true`

        // false false false false false true true true
        //                               ^
        // The idea is to get _first_ index which for which predicate returns `true`

        let lastIndex = count

        // The index that represetns where bad values starts.
        var badIndex = -1

        // The index that represetns where good values starts
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

        // Corner case, we' re out of bound, no good items in array
        if midIndex == lastIndex {
            return nil
        }
        return goodIndex
    }
}
