@preconcurrency import SourceKittenFramework

public extension SyntaxKind {
    init?(shortName: Swift.String) {
        guard let kind = SyntaxKind(rawValue: "source.lang.swift.syntaxtype.\(shortName.lowercased())") else {
            return nil
        }
        self = kind
    }

    static let commentAndStringKinds: Set<SyntaxKind> = commentKinds.union([.string])

    static let commentKinds: Set<SyntaxKind> = [
        .comment, .commentMark, .commentURL,
        .docComment, .docCommentField,
    ]

    static let allKinds: Set<SyntaxKind> = [
        .argument, .attributeBuiltin, .attributeID, .buildconfigID,
        .buildconfigKeyword, .comment, .commentMark, .commentURL,
        .docComment, .docCommentField, .identifier, .keyword, .number,
        .objectLiteral, .parameter, .placeholder, .string,
        .stringInterpolationAnchor, .typeidentifier,
    ]

    /// Syntax kinds that don't have associated module info when getting their cursor info.
    static var kindsWithoutModuleInfo: Set<SyntaxKind> {
        [
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
            .docCommentField,
        ]
    }
}
