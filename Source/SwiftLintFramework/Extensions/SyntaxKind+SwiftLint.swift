//
//  SyntaxKind+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension SyntaxKind {
    init(shortName: Swift.String) throws {
        let prefix = "source.lang.swift.syntaxtype."
        guard let kind = SyntaxKind(rawValue: prefix + shortName.lowercaseString) else {
            throw ConfigurationError.UnknownConfiguration
        }
        self = kind
    }

    static func commentKeywordStringAndTypeidentifierKinds() -> [SyntaxKind] {
        return commentAndStringKinds() + [.Keyword, .Typeidentifier]
    }

    static func commentAndStringKinds() -> [SyntaxKind] {
        return commentKinds() + [.String]
    }

    static func commentKinds() -> [SyntaxKind] {
        return [.Comment, .CommentMark, .CommentURL, .DocComment, .DocCommentField]
    }

    static func allKinds() -> [SyntaxKind] {
        return [.Argument, .AttributeBuiltin, .AttributeID, .BuildconfigID, .BuildconfigKeyword,
                .Comment, .CommentMark, .CommentURL, .DocComment, .DocCommentField, .Identifier,
                .Keyword, .Number, .ObjectLiteral, .Parameter, .Placeholder, .String,
                .StringInterpolationAnchor, .Typeidentifier]
    }
}
