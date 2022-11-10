import IndexStore

/// Collects Swift symbol occurrences (declarations and references) across all source units.
struct OccurrenceCollector {
    /// The reader interface for a Swift source code unit.
    let units: [UnitReader]
    /// A map from source file paths to their record reader interfaces.
    let recordReaders: [String: [RecordReader]]

    /// Collects occurrences for all units.
    ///
    /// - returns: occurrences for all units.
    func collect() -> Occurrences {
        return units.map { unitReader -> Occurrences in
            collectSingle(unitReader: unitReader)
        }
        .reduce(into: Occurrences()) { $0.formUnion($1) }
    }

    /// Collects occurrences for a single unit.
    ///
    /// - parameter unitReader: The reader for the unit being collected.
    ///
    /// - returns: Occurrences for the specified unit.
    private func collectSingle(unitReader: UnitReader) -> Occurrences {
        var occurrences = Occurrences()
        // Empty source files have units but no records
        guard let recordReader = recordReaders[unitReader.mainFile] else {
            return occurrences
        }

        let exceptions = DeclarationCollectionException.all

        for recordReader in recordReader {
            recordReader.visitOccurrences { occurrence in
                if occurrence.roles.contains(.reference) && !occurrence.roles.contains(.extendedBy) {
                    occurrences.references.insert(occurrence.symbol.usr)
                    return
                } else if exceptions.skipCollecting(occurrence) {
                    return
                }

                occurrences.declarations.insert(
                    Declaration(
                        usr: occurrence.symbol.usr,
                        file: unitReader.mainFile,
                        line: occurrence.location.line,
                        column: occurrence.location.column,
                        name: occurrence.symbol.name,
                        module: unitReader.moduleName,
                        kind: .init(symbolKind: occurrence.symbol.kind)
                    )
                )
            }
        }

        return occurrences
    }
}

private extension Declaration.Kind {
    init?(symbolKind: SymbolKind) {
        switch symbolKind {
        case .instanceProperty:
            self = .instanceProperty
        case .instanceMethod:
            self = .instanceMethod
        case .class:
            self = .class
        case .enumConstant:
            self = .enumCase
        case .constructor:
            self = .initializer
        default:
            return nil
        }
    }
}

private extension Array where Element == DeclarationCollectionException {
    func skipCollecting(_ occurrence: SymbolOccurrence) -> Bool {
        contains(where: { $0.skipCollectingOccurrence(occurrence) })
    }
}
