import IndexStore

// MARK: - ProtocolGraph

/// Graph of protocol definitions, along with information about which types conform to which protocols.
struct ProtocolGraph {
    /// Protocol definitions that compose this graph.
    let protocols: [ProtocolDefinition]

    /// Returns true if the specified occurrence satisfies a protocol requirement for any of the protocols in
    /// this graph.
    ///
    /// - parameter occurrence: The symbol occurrence definition to check.
    ///
    /// - returns: True if the specified occurrence satisfies a protocol requirement for any of the protocols
    ///            in this graph.
    func occurrenceSatisfiesProtocolRequirement(_ occurrence: SymbolOccurrence) -> Bool {
        guard occurrence.roles.contains(.definition),
              SymbolKind.protocolRequirementKinds.contains(occurrence.symbol.kind),
            let occurrenceParentName = occurrence.parentName()
        else {
            return false
        }

        return protocolsConformedByType(named: occurrenceParentName)
            .flatMap(\.childNames)
            .contains(occurrence.symbol.name)
    }

    // MARK: - Private

    private func protocolsConformedByType(named typeName: String) -> Set<ProtocolDefinition> {
        // First check protocols the type name directly conforms to.
        var protocolsConformedByType = Set(protocols).filter { protocolDefinition in
            return protocolDefinition.conformingNamesIncludingSelf
                .contains(typeName)
        }

        guard !protocolsConformedByType.isEmpty else {
            return []
        }

        // For all direct protocols, traverse their inheritance hierarchy in the graph, up to some limit to
        // make sure we don't infinitely recurse. Type-checking Swift code shouldn't hit this limit.
        var maxProtocolRecursion = 20
        while maxProtocolRecursion > 0 {
            let update = protocols.filter { protocolDefinition in
                if protocolsConformedByType.map(\.name).contains(protocolDefinition.name) {
                    // Exclude protocols we've already collected.
                    return false
                }

                return protocolDefinition.conformingNames
                    .contains(where: { newProtoConformingName in
                        protocolsConformedByType.map(\.name).contains(newProtoConformingName)
                    })
            }

            if update.isEmpty {
                // No more protocols to check in the hierarchy.
                break
            } else {
                protocolsConformedByType.formUnion(update)
                maxProtocolRecursion -= 1
            }
        }

        return protocolsConformedByType
    }
}

// MARK: - Private Helpers

private extension SymbolOccurrence {
    func parentName() -> String? {
        return mapFirstRelation(
            matching: { _, roles in roles.contains(.childOf) },
            transform: { symbol, _ in symbol.name }
        )
    }
}
