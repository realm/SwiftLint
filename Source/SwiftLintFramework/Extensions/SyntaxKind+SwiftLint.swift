//
//  SyntaxKind+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension SyntaxKind {
    // swiftlint:disable:next function_body_length
    init(shortName: Swift.String) throws {
        switch shortName.lowercaseString {
        case "argument":
            self = .Argument
        case "attribute_builtin":
            self = .AttributeBuiltin
        case "attribute_id":
            self = .AttributeID
        case "buildconfig_id":
            self = .BuildconfigID
        case "buildconfig_keyword":
            self = .BuildconfigKeyword
        case "comment":
            self = .Comment
        case "comment_mark":
            self = .CommentMark
        case "comment_url":
            self = .CommentURL
        case "doccomment":
            self = .DocComment
        case "doccomment_field":
            self = .DocCommentField
        case "identifier":
            self = .Identifier
        case "keyword":
            self = .Keyword
        case "number":
            self = .Number
        case "objectliteral":
            self = .ObjectLiteral
        case "parameter":
            self = .Parameter
        case "placeholder":
            self = .Placeholder
        case "string":
            self = .String
        case "string_interpolation_anchor":
            self = .StringInterpolationAnchor
        case "typeidentifier":
            self = .Typeidentifier
        default:
            throw ConfigurationError.UnknownConfiguration
        }
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
