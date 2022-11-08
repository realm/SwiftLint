import Foundation
import SourceKittenFramework

extension SyntaxKind {
    /// Returns if the syntax kind is comment-like.
    var isCommentLike: Bool {
        return Self.commentKinds.contains(self)
    }
}

struct TodoRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "todo",
        name: "Todo",
        description: "TODOs and FIXMEs should be resolved.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// notaTODO:\n"),
            Example("// notaFIXME:\n")
        ],
        triggeringExamples: [
            Example("// ↓TODO:\n"),
            Example("// ↓FIXME:\n"),
            Example("// ↓TODO(note)\n"),
            Example("// ↓FIXME(note)\n"),
            Example("/* ↓FIXME: */\n"),
            Example("/* ↓TODO: */\n"),
            Example("/** ↓FIXME: */\n"),
            Example("/** ↓TODO: */\n")
        ].skipWrappingInCommentTests()
    )

    private func customMessage(file: SwiftLintFile, range: NSRange) -> String {
        var reason = Self.description.description
        let offset = NSMaxRange(range)

        guard let (lineNumber, _) = file.stringView.lineAndCharacter(forCharacterOffset: offset) else {
            return reason
        }

        let line = file.lines[lineNumber - 1]
        // customizing the reason message to be specific to fixme or todo
        let violationSubstring = file.stringView.substring(with: range)

        let range = NSRange(location: offset, length: NSMaxRange(line.range) - offset)
        var message = file.stringView.substring(with: range)
        let kind = violationSubstring.hasPrefix("FIXME") ? "FIXMEs" : "TODOs"

        // trim whitespace
        message = message.trimmingCharacters(in: .whitespacesAndNewlines)

        // limiting the output length of todo message
        let maxLengthOfMessage = 30
        if message.utf16.count > maxLengthOfMessage {
            let index = message.index(message.startIndex,
                                      offsetBy: maxLengthOfMessage,
                                      limitedBy: message.endIndex) ?? message.endIndex
            message = message[..<index] + "..."
        }

        if message.isEmpty {
            reason = "\(kind) should be resolved."
        } else {
            reason = "\(kind) should be resolved (\(message))."
        }

        return reason
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return file.match(pattern: "\\b(?:TODO|FIXME)(?::|\\b)").compactMap { range, syntaxKinds in
            if syntaxKinds.contains(where: { !$0.isCommentLike }) {
                return nil
            }
            let reason = customMessage(file: file, range: range)

            return StyleViolation(ruleDescription: Self.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location),
                                  reason: reason)
        }
    }
}
