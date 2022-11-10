/// An error produced by the dead code tool.
enum DeadCodeError: Error, CustomStringConvertible {
    /// Failed to load the index store.
    case indexStoreLoadFailure(indexStoreError: Error)
    /// Failed to load units from index store.
    case noUnits
    /// Failed to load record from index store.
    case recordLoadFailure(recordName: String, recordReaderError: Error)

    var description: String {
        switch self {
        case .indexStoreLoadFailure(indexStoreError: let indexStoreError):
            return "Failed to open index store: \(indexStoreError)"
        case .noUnits:
            return "Failed to load units from index store"
        case let .recordLoadFailure(recordName: recordName, recordReaderError: recordReaderError):
            return "Failed to load record from index store: \(recordName) \(recordReaderError)"
        }
    }
}
