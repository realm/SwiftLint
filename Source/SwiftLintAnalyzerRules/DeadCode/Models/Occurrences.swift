/// A collection of symbol occurrences, both declarations and references.
/// Acts as a container pairing what's defined with what's used.
struct Occurrences {
    /// The source declarations defined.
    var declarations: Set<Declaration>
    /// The source symbols referenced.
    var references: Set<String>

    /// Creates an empty `Occurrences` value.
    init() {
        declarations = []
        references = []
    }

    /// Combines the current set of occurrences with the other set of occurrences specified.
    ///
    /// - parameter other: A different set of occurrences to combine with the current set.
    mutating func formUnion(_ other: Occurrences) {
        declarations.formUnion(other.declarations)
        references.formUnion(other.references)
    }
}
