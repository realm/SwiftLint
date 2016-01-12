//
//  TodoRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

extension SyntaxKind {
    /// Returns if the syntax kind is comment-like.
    public var isCommentLike: Bool {
        return [Comment, CommentMark, CommentURL, DocComment, DocCommentField].contains(self)
    }
}

public struct TodoRule: Rule {

    public init() {}

    public static let description = RuleDescription(
        identifier: "todo",
        name: "Todo",
        description: "TODOs and FIXMEs should be avoided.",
        nonTriggeringExamples: [
            "// notaTODO:\n",
            "// notaFIXME:\n"
        ],
        triggeringExamples: [
            "// ↓TODO:\n",
            "// ↓FIXME:\n",
            "// ↓TODO(note)\n",
            "// ↓FIXME(note)\n",
            "/* ↓FIXME: */\n",
            "/* ↓TODO: */\n",
            "/** ↓FIXME: */\n",
            "/** ↓TODO: */\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("\\b(TODO|FIXME)\\b").flatMap { range, syntaxKinds in
            if !syntaxKinds.filter({ !$0.isCommentLike }).isEmpty {
                return nil
            }
            return StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: range.location))
        }
    }
}
