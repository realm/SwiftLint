/// User-facing documentation for a SwiftLint rule.
struct RuleDocumentation {
    private let ruleType: Rule.Type

    var isOptInRule: Bool {
        return ruleType is OptInRule.Type
    }

    /// Creates a RuleDocumentation instance from a Rule type.
    ///
    /// - parameter ruleType: A subtype of the `Rule` protocol to document.
    init(_ ruleType: Rule.Type) {
        self.ruleType = ruleType
    }

    /// The name of the documented rule.
    var ruleName: String {
        return ruleType.description.name
    }

    /// The identifier of the documented rule.
    var ruleIdentifier: String {
        return ruleType.description.identifier
    }

    /// The name of the file on disk for this rule documentation.
    var fileName: String {
        return "\(ruleType.description.identifier).md"
    }

    /// The contents of the file for this rule documentation.
    var fileContents: String {
        let description = ruleType.description
        var content = [h1(description.name), description.description, detailsSummary(ruleType.init())]
        let nonTriggeringExamples = description.nonTriggeringExamples.filter { !$0.excludeFromDocumentation }
        if nonTriggeringExamples.isNotEmpty {
            content += [h2("Non Triggering Examples")]
            content += nonTriggeringExamples.map(formattedCode)
        }
        let triggeringExamples = description.triggeringExamples.filter { !$0.excludeFromDocumentation }
        if triggeringExamples.isNotEmpty {
            content += [h2("Triggering Examples")]
            content += triggeringExamples.map(formattedCode)
        }
        return content.joined(separator: "\n\n")
    }
}

private func h1(_ text: String) -> String {
    return "# \(text)"
}

private func h2(_ text: String) -> String {
    return "## \(text)"
}

private func detailsSummary(_ rule: Rule) -> String {
    return """
        * **Identifier:** \(type(of: rule).description.identifier)
        * **Enabled by default:** \(rule is OptInRule ? "No" : "Yes")
        * **Supports autocorrection:** \(rule is CorrectableRule ? "Yes" : "No")
        * **Kind:** \(type(of: rule).description.kind)
        * **Analyzer rule:** \(rule is AnalyzerRule ? "Yes" : "No")
        * **Minimum Swift compiler version:** \(type(of: rule).description.minSwiftVersion.rawValue)
        * **Default configuration:** \(rule.configurationDescription)
        """
}

private func formattedCode(_ example: Example) -> String {
    return """
        ```swift
        \(example.code)
        ```
        """
}
