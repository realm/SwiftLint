import SwiftSyntax

/// Provides a common interface for StructDeclSyntax, ClassDeclSyntax, and EnumDeclSyntax
protocol DeclSyntaxTraits {
    var inheritanceClause: TypeInheritanceClauseSyntax? { get }
    var modifiers: ModifierListSyntax? { get }
    var identifier: TokenSyntax { get }
}

extension DeclSyntaxTraits {
    /// Convenience variable to collect all inherited types from a declaration syntax node
    var inheritance: [String] {
        inheritanceClause?.inheritedTypeCollection.map { $0.typeName.description.trimmed } ?? []
    }

    /// Convenience variable for the declaration name
    var name: String {
        identifier.text.trimmed
    }
}

extension StructDeclSyntax: DeclSyntaxTraits {}

extension ClassDeclSyntax: DeclSyntaxTraits {}

extension EnumDeclSyntax: DeclSyntaxTraits {}
