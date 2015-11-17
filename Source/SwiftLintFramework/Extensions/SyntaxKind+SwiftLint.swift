//
//  SyntaxKind+SwiftLint.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-11-17.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension SyntaxKind {
    static func commentAndStringKinds() -> [SyntaxKind] {
        return [.Comment, .CommentMark, .CommentURL, .DocComment, .DocCommentField, .String]
    }
}
