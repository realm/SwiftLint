import CollectionConcurrencyKit
import IndexStore
import SwiftLintCore
import SwiftSyntax

// MARK: - ProtocolCollector

/// Collects Swift symbol occurrences (declarations and references) across all source units.
struct ProtocolCollector {
    /// The reader interface for a Swift source code unit.
    let units: [UnitReader]
    /// A map from source file paths to their record reader interfaces.
    let recordReaders: [String: [RecordReader]]

    /// Builds a protocol graph.
    ///
    /// - returns: The protocol graph.
    func collect() async -> ProtocolGraph {
        await units
            .concurrentCompactMap(collectSingle(unitReader:))
            .reduce(into: ProtocolCollectionResult()) { $0.merge(with: $1) }
            .toProtocolGraph()
    }

    // MARK: - Private

    private func collectSingle(unitReader: UnitReader) -> ProtocolCollectionResult? {
        // Empty source files have units but no records
        guard let recordReader = recordReaders[unitReader.mainFile] else {
            return nil
        }

        return recordReader.reduce(into: ProtocolCollectionResult()) { result, recordReader in
            recordReader.visitOccurrences(matching: { $0.roles.contains(.definition) }, visitor: { occurrence in
                if let protocolDefinition = occurrence.protocolDefinition {
                    result.mergeOrAppend(protocolDefinition)
                }

                if occurrence.canAddProtocolConformance {
                    let tree = FileSyntaxTreeCache.getSyntaxTree(forFile: unitReader.mainFile)
                    for protocolName in occurrence.conformances(in: tree) {
                        result.conformances[protocolName, default: []].append(occurrence.symbol.name)
                    }
                } else if let protocolDefinition = occurrence.protocolDefinitionForRequirement {
                    result.mergeOrAppend(protocolDefinition)
                }
            })
        }
    }
}

// MARK: - Private Helpers

private extension SymbolOccurrence {
    func conformances(in tree: SourceFileSyntax) -> [String] {
        ConformanceVisitor(symbolName: symbol.name)
            .walk(tree: tree, handler: \.conformances)
    }

    var canAddProtocolConformance: Bool {
        symbol.kind == .extension || symbol.kind == .protocol || symbol.kind == .typealias
    }

    var protocolDefinition: ProtocolDefinition? {
        guard symbol.kind == .protocol || symbol.kind == .typealias else {
            return nil
        }

        return ProtocolDefinition(
            usr: symbol.usr, name: symbol.name,
            conformingNames: [], // Added later
            childNames: [] // Added later
        )
    }

    var protocolDefinitionForRequirement: ProtocolDefinition? {
        guard SymbolKind.protocolRequirementKinds.contains(symbol.kind) else {
            return nil
        }

        return mapFirstRelation(
            matching: { $0.kind == .protocol && $1.contains(.childOf) },
            transform: { symbol, _ in
                ProtocolDefinition(
                    usr: symbol.usr, name: symbol.name,
                    conformingNames: [], // Added later
                    childNames: [self.symbol.name]
                )
            }
        )
    }
}

private struct ProtocolCollectionResult {
    var protocols: [ProtocolDefinition] = []
    // Key is protocol name, value is set of type names that conform to that protocol
    var conformances: [String: [String]] = [:]

    mutating func merge(with other: ProtocolCollectionResult) {
        other.protocols
            .forEach { mergeOrAppend($0) }
        other.conformances
            .forEach { conformances[$0.key, default: []].append(contentsOf: $0.value) }
    }

    mutating func mergeOrAppend(_ definition: ProtocolDefinition) {
        if let existingDefinition = protocols.first(where: { $0.usr == definition.usr }) {
            existingDefinition.merge(with: definition)
        } else {
            protocols.append(definition)
        }
    }

    func toProtocolGraph() -> ProtocolGraph {
        protocols.forEach { $0.conformingNames = conformances[$0.name] ?? [] }
        return ProtocolGraph(protocols: protocols)
    }
}
