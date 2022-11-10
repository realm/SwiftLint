import Foundation
import IndexStore

/// Collects Swift source units and their associated record readers.
struct UnitCollector {
    /// The index store to traverse to collect units.
    let indexStore: IndexStore

    /// Collects all source units and record readers.
    ///
    /// - throws: `DeadCodeError` if no units were found, or if a record reader could not be created.
    ///
    /// - returns: All source units and record readers.
    func collectUnitsAndRecords() throws -> ([UnitReader], [String: [RecordReader]]) {
        let units = indexStore.units.filter(\.shouldCollectUnitsAndRecords)

        if units.isEmpty {
            throw DeadCodeError.noUnits
        }

        let recordReaders = try units.reduce(into: [String: [RecordReader]]()) { accumulator, unitReader in
            guard let recordName = unitReader.recordName else {
                return
            }

            let recordReader: RecordReader
            do {
                recordReader = try RecordReader(indexStore: indexStore, recordName: recordName)
            } catch {
                throw DeadCodeError.recordLoadFailure(recordName: recordName, recordReaderError: error)
            }

            accumulator[unitReader.mainFile, default: []].append(recordReader)
        }

        return (units, recordReaders)
    }
}

private extension UnitReader {
    var shouldCollectUnitsAndRecords: Bool {
        !mainFile.contains("/.build/") &&
            !mainFile.contains("/external/")
    }
}
