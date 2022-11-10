import IndexStore

extension SymbolKind {
    /// All kinds that could be used to define or satisfy a protocol requirement.
    static var protocolRequirementKinds: [SymbolKind] {
        [
            .instanceMethod, .classMethod, .staticMethod,
            .instanceProperty, .classProperty, .staticProperty
        ]
    }
}
