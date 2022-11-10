import SwiftSyntax

// MARK: - SkippableInitVisitor

/// A SwiftSyntax visitor that detects if the initializer at the specified line number should be excluded
/// from being reported as dead code.
final class SkippableInitVisitor: SyntaxVisitor {
    var unusedDeclarationException = false
    private let line: Int
    private let locationConverter: SourceLocationConverter

    init(line: Int, locationConverter: SourceLocationConverter) {
        self.line = line
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
        guard node.includesLine(self.line, sourceLocationConverter: self.locationConverter) else {
            return
        }

        // TODO: Remove some of these exceptions

        guard let parent = node.nearestNominalOrExtensionParent() else {
            return
        }

        // Skip initializers of types with generic parameters since Swift doesn't record references to these
        // in the index store.
        if parent.as(StructDeclSyntax.self)?.genericParameterClause != nil ||
            parent.as(ClassDeclSyntax.self)?.genericParameterClause != nil {
            self.unusedDeclarationException = true
        }

        // Skip initializers of non-final classes.
        if let classDecl = parent.as(ClassDeclSyntax.self),
           classDecl.modifiers?.hasFinalKeyword != true {
            self.unusedDeclarationException = true
        }

        // Skip extensions of `Array`.
        if let extensionDecl = parent.as(ExtensionDeclSyntax.self),
           let extendedType = extensionDecl.extendedType.as(SimpleTypeIdentifierSyntax.self),
           extendedType.name.text == "Array" {
            self.unusedDeclarationException = true
        }

        // Skip extensions with `where` clause.
        if let extensionDecl = parent.as(ExtensionDeclSyntax.self),
           extensionDecl.genericWhereClause != nil {
            self.unusedDeclarationException = true
        }

        // Skip initializers marked as `required`.
        if node.modifiers?.hasRequiredKeyword == true {
            self.unusedDeclarationException = true
        }
    }
}

// MARK: - Private Helpers

private extension ModifierListSyntax {
    var hasRequiredKeyword: Bool {
        self.contains { $0.name.tokenKind == .keyword(.required) }
    }

    var hasFinalKeyword: Bool {
        self.contains { $0.name.tokenKind == .keyword(.final) }
    }
}

private extension SyntaxProtocol {
    func nearestNominalOrExtensionParent() -> Syntax? {
        guard let parent else {
            return nil
        }

        return parent.isNominalTypeDeclOrExtensionDecl ? parent : parent.nearestNominalOrExtensionParent()
    }
}

private extension Syntax {
    var isNominalTypeDeclOrExtensionDecl: Bool {
        self.is(StructDeclSyntax.self) ||
            self.is(ClassDeclSyntax.self) ||
            self.is(ActorDeclSyntax.self) ||
            self.is(EnumDeclSyntax.self) ||
            self.is(ExtensionDeclSyntax.self)
    }
}
