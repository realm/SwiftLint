import SourceKittenFramework

public extension SyntaxKind {
    init(shortName: Swift.String) throws {
        let prefix = "source.lang.swift.syntaxtype."
        guard let kind = SyntaxKind(rawValue: prefix + shortName.lowercased()) else {
            throw ConfigurationError.unknownConfiguration
        }
        self = kind
    }

    static let commentAndStringKinds: Set<SyntaxKind> = commentKinds.union([.string])

    static let commentKinds: Set<SyntaxKind> = [.comment, .commentMark, .commentURL,
                                                .docComment, .docCommentField]

    static let allKinds: Set<SyntaxKind> = [.argument, .attributeBuiltin, .attributeID, .buildconfigID,
                                            .buildconfigKeyword, .comment, .commentMark, .commentURL,
                                            .docComment, .docCommentField, .identifier, .keyword, .number,
                                            .objectLiteral, .parameter, .placeholder, .string,
                                            .stringInterpolationAnchor, .typeidentifier]

    /// Syntax kinds that don't have associated module info when getting their cursor info.
    static var kindsWithoutModuleInfo: Set<SyntaxKind> {
        return [
            .attributeBuiltin,
            .keyword,
            .number,
            .docComment,
            .string,
            .stringInterpolationAnchor,
            .attributeID,
            .buildconfigKeyword,
            .buildconfigID,
            .commentURL,
            .comment,
            .docCommentField
        ]
    }
}
