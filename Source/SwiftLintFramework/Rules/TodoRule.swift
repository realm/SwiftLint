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
        return [
            SyntaxKind.comment,
            SyntaxKind.commentMark,
            SyntaxKind.commentURL,
            SyntaxKind.docComment,
            SyntaxKind.docCommentField
            ].contains(self)
    }
}

public struct TodoRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

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

    fileprivate func customMessage(_ lines: [Line], location: Location) -> String {
            var reason = type(of: self).description.description

            guard let lineIndex = location.line,
                  let currentLine = lines.filter({ $0.index == lineIndex }).first
                  else { return reason }

            // customizing the reason message to be specific to fixme or todo
            var message = currentLine.content
            if currentLine.content.contains("FIXME") {
                reason = "FIXMEs should be avoided"
                message = message.replacingOccurrences(of: "FIXME", with: "")
            } else {
                reason = "TODOs should be avoided"
                message = message.replacingOccurrences(of: "TODO", with: "")
            }
            message = message.replacingOccurrences(of: "//", with: "")
            // trim whitespace
            message = message.trimmingCharacters(in: .whitespacesAndNewlines)

            // limiting the output length of todo message
            let maxLengthOfMessage = 30
            if message.utf16.count > maxLengthOfMessage {
                let index = message.index(message.startIndex,
                                          offsetBy: maxLengthOfMessage,
                                          limitedBy: message.endIndex) ?? message.endIndex
                reason += message.substring(to: index) + "..."
            } else {
                reason += message
            }

            return reason
    }

    public func validateFile(_ file: File) -> [StyleViolation] {
        return file.matchPattern("\\b(TODO|FIXME)\\b").flatMap { range, syntaxKinds in
            if !syntaxKinds.filter({ !$0.isCommentLike }).isEmpty {
                return nil
            }
            let location = Location(file: file, characterOffset: range.location)
            let reason = customMessage(file.lines, location: location)

            return StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: location,
                reason: reason )
        }
    }
}
