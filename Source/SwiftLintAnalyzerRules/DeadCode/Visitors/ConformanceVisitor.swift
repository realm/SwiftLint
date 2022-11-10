import SwiftSyntax

// MARK: - ConformanceVisitor

/// Visits the source syntax tree to collect the types the specified `symbolName` conform to.
final class ConformanceVisitor: SyntaxVisitor {
    var conformances = [String]()
    let symbolName: String

    init(symbolName: String) {
        self.symbolName = symbolName
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: TypealiasDeclSyntax) {
        if node.identifier.text == symbolName,
           let compositionTypeNames = node.compositionTypeNames() {
            conformances.append(contentsOf: compositionTypeNames)
        }
    }

    override func visitPost(_ node: GenericWhereClauseSyntax) {
        for child in node.requirementList.children(viewMode: .sourceAccurate) {
            if let genericRequirement = child.as(GenericRequirementSyntax.self),
               let conformanceRequirement = genericRequirement.body.as(ConformanceRequirementSyntax.self),
               let leftTypeIdentifier = conformanceRequirement.leftTypeIdentifier
                .as(SimpleTypeIdentifierSyntax.self),
               leftTypeIdentifier.firstToken?.tokenKind == .capitalSelfKeyword,
               let rightTypeName = conformanceRequirement.rightTypeIdentifier.simpleTypeName,
               let parent = node.parent, let extensionDecl = parent.as(ExtensionDeclSyntax.self),
               let extendedTypeName = extensionDecl.extendedType.simpleTypeName,
               extendedTypeName == symbolName {
                conformances.append(rightTypeName)
            }
        }
    }

    override func visitPost(_ node: InheritedTypeListSyntax) {
        guard node.parent?.parent?.declIdentifierName == symbolName else {
            return
        }

        for child in node.children(viewMode: .sourceAccurate) {
            if let inheritedTypeName = child.as(InheritedTypeSyntax.self)?.typeName.simpleTypeName {
                conformances.append(inheritedTypeName)
            }
        }
    }
}

// MARK: - Private Helpers

private extension TypealiasDeclSyntax {
    func compositionTypeNames() -> [String]? {
        guard let elements = initializer.value.as(CompositionTypeSyntax.self)?.elements else {
            return nil
        }

        return elements.children(viewMode: .sourceAccurate).compactMap { child in
            child.as(CompositionTypeElementSyntax.self)?.type.simpleTypeName
        }
    }
}

private extension TypeSyntax {
    var simpleTypeName: String? {
        self.as(SimpleTypeIdentifierSyntax.self)?.name.text
    }
}

private extension Syntax {
    var declIdentifierName: String? {
        if let decl = self.as(ClassDeclSyntax.self) {
            return decl.identifier.text
        } else if let decl = self.as(ProtocolDeclSyntax.self) {
            return decl.identifier.text
        } else if let decl = self.as(StructDeclSyntax.self) {
            return decl.identifier.text
        } else if let decl = self.as(ExtensionDeclSyntax.self) {
            return decl.extendedType.simpleTypeName
        } else {
            return nil
        }
    }
}
