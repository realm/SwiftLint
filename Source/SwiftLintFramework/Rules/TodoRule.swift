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

public struct TodoRule: ConfigProviderRule {

    public var config = SeverityConfig(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "todo",
        name: "Todo",
        description: "TODOs and FIXMEs should be avoided.",
        nonTriggeringExamples: [
            Trigger("// notaTODO:\n"),
            Trigger("// notaFIXME:\n")
        ],
        triggeringExamples: [
            Trigger("// ↓TODO:\n"),
            Trigger("// ↓FIXME:\n"),
            Trigger("// ↓TODO(note)\n"),
            Trigger("// ↓FIXME(note)\n"),
            Trigger("/* ↓FIXME: */\n"),
            Trigger("/* ↓TODO: */\n"),
            Trigger("/** ↓FIXME: */\n"),
            Trigger("/** ↓TODO: */\n")
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("\\b(TODO|FIXME)\\b").flatMap { range, syntaxKinds in
            if !syntaxKinds.filter({ !$0.isCommentLike }).isEmpty {
                return nil
            }
            return StyleViolation(ruleDescription: self.dynamicType.description,
                severity: config.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }
}
