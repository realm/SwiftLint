//
//  SyntaxKind+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 11/17/15.
//  Copyright © 2015 Realm. All rights reserved.
//

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
