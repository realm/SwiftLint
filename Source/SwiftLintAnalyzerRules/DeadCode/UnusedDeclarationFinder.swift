import IndexStore

/// Entry point to the dead code tool. Finds and produces all unused declarations.
public enum UnusedDeclarationFinder {
    /// Find and return all unused declarations from the index store.
    ///
    /// - parameter indexStorePath: The path on disk to the index store directory.
    ///
    /// - throws: `DeadCodeError` on failure.
    ///
    /// - returns: All unused declarations found.
    public static func find(indexStorePath: String) async throws -> [UnusedDeclaration] {
        let indexStore = try IndexStoreLoader(indexStorePath: indexStorePath)
            .load()

        let (units, recordReaders) = try TimedStep("(1/4) Collecting units and records") {
            try UnitCollector(indexStore: indexStore)
                .collectUnitsAndRecords()
        }

        let protocolGraph = await TimedStep("(2/4) Collecting protocol conformances") {
            await ProtocolCollector(units: units, recordReaders: recordReaders)
                .collect()
        }

        let occurrences = TimedStep("(3/4) Collecting declarations and references") {
            OccurrenceCollector(units: units, recordReaders: recordReaders)
                .collect()
        }

        return try await TimedStep("(4/4) Calculating unused declarations") {
            let calculator = UnusedDeclarationCalculator(
                units: units, recordReaders: recordReaders, protocolGraph: protocolGraph, occurrences: occurrences
            )
            return try await calculator.calculate()
        }
    }
}
