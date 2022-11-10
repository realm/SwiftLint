/// Definition of a protocol in the `ProtocolGraph`. A reference type to enable efficient in-place merging
/// with other protocol definitions.
final class ProtocolDefinition {
    /// This protocol's unique identifier.
    let usr: String
    /// This protocol's name.
    let name: String
    /// The set of type names that conform to this protocol.
    /// May be incomplete unless accessed through a `ProtocolGraph`.
    var conformingNames: [String]
    /// The names of this protocol's requirements.
    private(set) var childNames: [String]

    /// The set of type names that conform to this protocol, plus this protocol's name.
    /// May be incomplete unless accessed through a `ProtocolGraph`.
    var conformingNamesIncludingSelf: [String] { conformingNames + [name] }

    init(usr: String, name: String, conformingNames: [String], childNames: [String]) {
        self.usr = usr
        self.name = name
        self.conformingNames = conformingNames
        self.childNames = childNames
    }

    /// Adds the children of the specified protocol definition to the current definition.
    ///
    /// - parameter definition: The other protocol definition to merge with `self`.
    func merge(with definition: ProtocolDefinition) {
        childNames.append(contentsOf: definition.childNames)
        childNames = Set(childNames).sorted()
    }
}

// MARK: - Hashable

extension ProtocolDefinition: Hashable {
    static func == (lhs: ProtocolDefinition, rhs: ProtocolDefinition) -> Bool {
        return (lhs.usr, lhs.name, lhs.conformingNames, lhs.childNames) ==
            (rhs.usr, rhs.name, rhs.conformingNames, rhs.childNames)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(usr)
    }
}
