import IndexStore

// MARK: - RecordReader

extension RecordReader {
    /// Visits all the symbol occurrences referenced by this record reader that match the `matching`
    /// predicate.
    ///
    /// - parameter matching: Matching predicate. The visitor block will only be called if this returns true.
    /// - parameter visitor:  The block to run for occurrences passing the `matching` test.
    func visitOccurrences(matching: (SymbolOccurrence) -> Bool = { _ in true },
                          visitor: (SymbolOccurrence) -> Void) {
        forEach(occurrence: { occurrence in
            if matching(occurrence) {
                visitor(occurrence)
            }
        })
    }
}

// MARK: - SymbolOccurrence

extension SymbolOccurrence {
    /// Visits all this occurrence's related symbols and transforms the first relation passing the `matching`
    /// test with the `transform` closure, returning the result.
    ///
    /// - parameter matching:  Matching predicate. The transform block will only be called if this returns
    ///                        true.
    /// - parameter transform: The transformation to apply to the first relationship passing the `matching`
    ///                        test.
    ///
    /// - returns: The result of the transformation, or nil if no relationship passed the `matching` test.
    func mapFirstRelation<T>(
        matching: (Symbol, SymbolRoles) -> Bool,
        transform: (Symbol, SymbolRoles) -> T
    ) -> T? {
        var result: T?
        forEach(relation: { symbol, roles in
            if result == nil && matching(symbol, roles) {
                result = transform(symbol, roles)
            }
        })
        return result
    }
}
