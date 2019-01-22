import SourceKittenFramework

extension SyntaxKind {
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
}

extension Set where Element == SyntaxKind {
    init(shortName: Swift.String) throws {
        do {
            self = try [SyntaxKind(shortName: shortName)]
        } catch {
            switch shortName {
            case "comment_and_string_kinds":
                self = SyntaxKind.commentAndStringKinds
            case "comment_kinds":
                self = SyntaxKind.commentKinds
            case "all_kinds":
                self = SyntaxKind.allKinds
            default: throw error
            }
        }
    }
}
