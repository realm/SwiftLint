import IndexStore

/// Opens and parses index stores.
struct IndexStoreLoader {
    /// The path on disk to the index store directory.
    let indexStorePath: String

    /// Open and parse the index store.
    ///
    /// - throws: `DeadCodeError` if the loading fails.
    ///
    /// - returns: The index store.
    func load() throws -> IndexStore {
        do {
            return try IndexStore(path: indexStorePath)
        } catch {
            throw DeadCodeError.indexStoreLoadFailure(indexStoreError: error)
        }
    }
}
