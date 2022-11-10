import CollectionConcurrencyKit
import IndexStore

// MARK: - UnusedDeclarationCalculator

/// Calculates which declarations are unused based on the input occurrences that were collected, applying
/// exceptions as defined in `UnusedDeclarationException.all`.
struct UnusedDeclarationCalculator {
    /// The reader interface for a Swift source code unit.
    let units: [UnitReader]
    /// A map from source file paths to their record reader interfaces.
    let recordReaders: [String: [RecordReader]]
    /// The protocol graph.
    let protocolGraph: ProtocolGraph
    /// The collection of symbol occurrences, both declarations and references.
    let occurrences: Occurrences

    /// Calculates which declarations are unused based on the input occurrences.
    ///
    /// - returns: All unused declarations based on the input occurrences.
    func calculate() async throws -> [UnusedDeclaration] {
        let exceptions = UnusedDeclarationException.all

        var unusedDeclarations = await occurrences.declarations.concurrentCompactMap { declaration -> Declaration? in
            if occurrences.references.contains(declaration.usr) {
                return nil
            }

            let tree = FileSyntaxTreeCache.getSyntaxTree(forFile: declaration.file)
            if exceptions.contains(where: { $0.skipReportingUnusedDeclaration(declaration, tree) }) {
                return nil
            }

            return declaration
        }

        // Declarations that satisfy protocol requirements in files other than where the parent type adds
        // the conformance to the protocol aren't detected as relationships in the index store.
        // We can remove these cases by checking if a USR satisfies a protocol requirement from the protocol
        // graph we built ourselves.
        let usrsToRemove = usrsSatisfyingProtocolRequirements(Set(unusedDeclarations.map(\.usr)))
        unusedDeclarations.removeAll { usrsToRemove.contains($0.usr) }

        return unusedDeclarations
            .sorted()
            .map(UnusedDeclaration.init)
    }

    // MARK: - Private

    private func usrsSatisfyingProtocolRequirements(_ usrsToCheck: Set<String>) -> Set<String> {
        guard !usrsToCheck.isEmpty else {
            return []
        }

        return units.compactMap { unitReader -> Set<String>? in
            guard let recordReader = recordReaders[unitReader.mainFile] else {
                return nil
            }

            return recordReader.reduce(into: Set<String>()) { usrsToRemove, recordReader in
                recordReader.visitOccurrences(
                    matching: { occurrence in
                        usrsToCheck.contains(occurrence.symbol.usr) &&
                            protocolGraph.occurrenceSatisfiesProtocolRequirement(occurrence)
                    },
                    visitor: { usrsToRemove.insert($0.symbol.usr) }
                )
            }
        }
        .reduce(into: []) { $0.formUnion($1) }
    }
}
