//
//  RuleList+Documentation.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 8/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

extension RuleList {
    public func generateDocumentation() -> String {
        let rules = list.sorted { $0.0 < $1.0 }.map { $0.value }
        let rulesText = rules.map(ruleMarkdown)
        let rulesSummary = rules.map(ruleSummary)

        var text = h1("Rules")
        text += rulesSummary.joined()
        text += "--------\n"
        text += rulesText.joined(separator: "\n\n")

        return text
    }

    private func ruleSummary(_ rule: Rule.Type) -> String {
        return summaryItem(rule.description.name)
    }

    private func ruleMarkdown(_ rule: Rule.Type) -> String {
        let description = rule.description
        var content = h2(description.name)
        content += detailsSummary(rule.init())
        content += description.description + "\n"

        if !description.nonTriggeringExamples.isEmpty || !description.triggeringExamples.isEmpty {
            content += h3("Examples")
        }

        if !description.nonTriggeringExamples.isEmpty {
            let examples = description.nonTriggeringExamples.map(formattedCode).joined(separator: "\n")
            content += details(summary: "Non Triggering Examples", details: examples)
        }

        if !description.triggeringExamples.isEmpty {
            let examples = description.triggeringExamples.map(formattedCode).joined(separator: "\n")
            content += details(summary: "Triggering Examples", details: examples)
        }

        return content
    }

    private func details(summary: String, details: String) -> String {
        var content = "<details>\n"
        content += "<summary>\(summary)</summary>\n\n"
        content += details + "\n"
        content += "</details>\n"

        return content
    }

    private func formattedCode(_ code: String) -> String {
        var content = "```swift\n"
        content += code
        content += "\n```\n"

        return content
    }

    private func detailsSummary(_ rule: Rule) -> String {
        var content = "Identifier | Enabled by default | Supports autocorrection | Kind \n"
        content += "--- | --- | --- | ---\n"
        let identifier = type(of: rule).description.identifier
        let defaultStatus = rule is OptInRule ? "Disabled" : "Enabled"
        let correctable = rule is CorrectableRule ? "Yes" : "No"
        let kind = type(of: rule).description.kind
        content += "`\(identifier)` | \(defaultStatus) | \(correctable) | \(kind)\n\n"

        return content
    }

    private func h1(_ text: String) -> String {
        return "\n# \(text)\n\n"
    }

    private func h2(_ text: String) -> String {
        return "\n## \(text)\n\n"
    }

    private func h3(_ text: String) -> String {
        return "\n### \(text)\n\n"
    }

    private func summaryItem(_ text: String) -> String {
        let anchor = text.lowercased().components(separatedBy: .whitespaces).joined(separator: "-")
        return "* [\(text)](#\(anchor))\n"
    }
}
