import SwiftSyntax

extension ModifierListSyntax {
    /// Convenience variable to collect all modifiers from a declaration syntax node
    var names: [String] {
        map { $0.name.text.trimmed }
    }
}
