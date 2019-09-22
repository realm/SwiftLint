import Foundation
import SourceKittenFramework

public struct TodoAttributionRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    private let todoPattern = "[tT][oO][-_]{0,1}[dD][oO]"
    private let fixmePattern = "[fF][iI][xX][-_]{0,1}[mM][eE]"
    private let ownerPattern = "@[:alnum:]+"
    private let issuePattern = "#[:alnum:]+"

    public init() {}

    public static let description = RuleDescription(
        identifier: "todo_attribution",
        name: "Todo Attribution",
        description: "TODOs and FIXMEs should be attributed to an owner or related issue",
        kind: .lint,
        nonTriggeringExamples: [
            "// TODO: @gituser ",
            "// FIXME: @GitUser this assumes 64 bit words",
            "// TODO: #4 Implement",
            "// FIXME: #134",
            "// TODO: @gituser #27 make async"
        ],
        triggeringExamples: [
            "// ↓TODO:  @gituser\n",
            "// ↓FIXME:  #2871\n",
            "// ↓TODO(#2871)\n",
            "// ↓FIXME(@gituser)\n",
            "/* ↓fixme: @gituser*/\n",
            "/* ↓todo: */\n",
            "/** ↓FIX_ME: */\n",
            "/** ↓TO-DO: */\n"
        ]
    )

    private func areThereMatches(of pattern: String, in string: String) -> Bool {
        let range = NSRange(location: 0, length: string.count)
        let regularExpression = regex(pattern)
        let matchRange = regularExpression.rangeOfFirstMatch(in: string, options: [], range: range)
        return matchRange.location != NSNotFound
    }

    private func customMessage(file: File, range: NSRange) -> String {
        var reason = type(of: self).description.description
        let offset = NSMaxRange(range)

        guard let (lineNumber, _) = file.contents.bridge().lineAndCharacter(forCharacterOffset: offset) else {
            return type(of: self).description.description
        }

        let line = file.lines[lineNumber - 1]
        let lineContent = line.content
        let kind = areThereMatches(of: todoPattern, in: lineContent) ? "TODO" : "FIXME"
        let hasOwner = areThereMatches(of: "\(ownerPattern)\\b", in: lineContent)
        let hasIssue = areThereMatches(of: "\(issuePattern)\\b", in: lineContent)

        switch (hasOwner, hasIssue) {
        case (false, false):
            let ownerExample = "(e.g. '\(kind): @gituser')"
            let issueExample = "(e.g. '\(kind): #2871')"
            reason = "\(kind)s should be attributed to their owner \(ownerExample) or related issue \(issueExample)."
        case (false, true):
            reason = "Expected \(kind) format is: '\(kind): #issue_identifier'."
        case (true, false):
            reason = "Expected \(kind) format is: '\(kind): @owner_handle'."
        case (true, true):
            reason = "Expected \(kind) format is: '\(kind): @owner_handle #issue_identifier'."
        }

        return reason
    }

    public func validate(file: File) -> [StyleViolation] {
        let validTodoPattern = "\\b(?:TODO|FIXME): (?:\(ownerPattern)|\(issuePattern))\\b"
        let rulePattern = "(?!\(validTodoPattern))\\b(?:(?:\(todoPattern))|(?:\(fixmePattern)))\\b"
        return file.match(pattern: rulePattern).compactMap { range, syntaxKinds in
            if syntaxKinds.contains(where: { !$0.isCommentLike }) {
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
