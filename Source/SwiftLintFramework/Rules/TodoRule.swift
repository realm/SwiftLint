//
//  TodoRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

extension SyntaxKind {
    /// Returns if the syntax kind is comment-like.
    public var isCommentLike: Bool {
        return [
            SyntaxKind.comment,
            .commentMark,
            .commentURL,
            .docComment,
            .docCommentField
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

    private func customMessage(file: File, range: NSRange) -> String {
        var reason = type(of: self).description.description
        let offset = NSMaxRange(range)

        guard let (lineNumber, _) = file.contents.bridge().lineAndCharacter(forCharacterOffset: offset) else {
            return reason
        }

        let line = file.lines[lineNumber - 1]
        // customizing the reason message to be specific to fixme or todo
        let violationSubstring = file.contents.bridge().substring(with: range)

        let range = NSRange(location: offset, length: NSMaxRange(line.range) - offset)
        var message = file.contents.bridge().substring(with: range)
        let kind = violationSubstring.hasPrefix("FIXME") ? "FIXMEs" : "TODOs"

        // trim whitespace
        message = message.trimmingCharacters(in: .whitespacesAndNewlines)

        // limiting the output length of todo message
        let maxLengthOfMessage = 30
        if message.utf16.count > maxLengthOfMessage {
            let index = message.index(message.startIndex,
                                      offsetBy: maxLengthOfMessage,
                                      limitedBy: message.endIndex) ?? message.endIndex
            message = message.substring(to: index) + "..."
        }

        if message.isEmpty {
            reason = "\(kind) should be avoided."
        } else {
            reason = "\(kind) should be avoided (\(message))."
        }

        return reason
    }

    public func validate(file: File) -> [StyleViolation] {
        return file.match(pattern: "\\b(?:TODO|FIXME)(?::|\\b)").flatMap { range, syntaxKinds in
            if !syntaxKinds.filter({ !$0.isCommentLike }).isEmpty {
                return nil
            }
            let reason = customMessage(file: file, range: range)

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location),
                                  reason: reason)
        }
    }
}
