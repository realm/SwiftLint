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

    static func commentKeywordStringAndTypeidentifierKinds() -> [SyntaxKind] {
        return commentAndStringKinds() + [.keyword, .typeidentifier]
    }

    static func commentAndStringKinds() -> [SyntaxKind] {
        return commentKinds() + [.string]
    }

    static func commentKinds() -> [SyntaxKind] {
        return [.comment, .commentMark, .commentURL, .docComment, .docCommentField]
    }

    static func allKinds() -> [SyntaxKind] {
        return [.argument, .attributeBuiltin, .attributeID, .buildconfigID, .buildconfigKeyword,
                .comment, .commentMark, .commentURL, .docComment, .docCommentField, .identifier,
                .keyword, .number, .objectLiteral, .parameter, .placeholder, .string,
                .stringInterpolationAnchor, .typeidentifier]
    }
}
