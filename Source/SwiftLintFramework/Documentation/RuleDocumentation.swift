/// User-facing documentation for a SwiftLint rule.
struct RuleDocumentation {
    private let ruleType: any Rule.Type

    /// If this rule is an opt-in rule.
    var isOptInRule: Bool { ruleType is any OptInRule.Type }

    /// If this rule is an analyzer rule.
    var isAnalyzerRule: Bool { ruleType is any AnalyzerRule.Type }

    /// If this rule is a linter rule.
    var isLinterRule: Bool { !isAnalyzerRule }

    /// If this rule uses SourceKit.
    var usesSourceKit: Bool { !(ruleType is any SourceKitFreeRule.Type) }

    /// If this rule is disabled by default.
    var isDisabledByDefault: Bool { ruleType is any OptInRule.Type }

    /// If this rule is enabled by default.
    var isEnabledByDefault: Bool { !isDisabledByDefault }

    /// Creates a RuleDocumentation instance from a Rule type.
    ///
    /// - parameter ruleType: A subtype of the `Rule` protocol to document.
    init(_ ruleType: any Rule.Type) {
        self.ruleType = ruleType
    }

    /// The name of the documented rule.
    var ruleName: String { ruleType.description.name }

    /// The identifier of the documented rule.
    var ruleIdentifier: String { ruleType.description.identifier }

    /// The name of the file on disk for this rule documentation.
    var fileName: String { "\(ruleType.description.identifier).md" }

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

private func h1(_ text: String) -> String { "# \(text)" }

private func h2(_ text: String) -> String { "## \(text)" }

private func detailsSummary(_ rule: some Rule) -> String {
    let ruleDescription = """
        * **Identifier:** \(type(of: rule).description.identifier)
        * **Enabled by default:** \(rule is any OptInRule ? "No" : "Yes")
        * **Supports autocorrection:** \(rule is any CorrectableRule ? "Yes" : "No")
        * **Kind:** \(type(of: rule).description.kind)
        * **Analyzer rule:** \(rule is any AnalyzerRule ? "Yes" : "No")
        * **Minimum Swift compiler version:** \(type(of: rule).description.minSwiftVersion.rawValue)
        """
    if rule.configurationDescription.hasContent {
        let configurationTable = rule.configurationDescription.markdown()
            .split(separator: "\n")
            .joined(separator: "\n  ")
        return ruleDescription + """

            * **Default configuration:**
              \(configurationTable)
            """
    }
    return ruleDescription
}

private func formattedCode(_ example: Example) -> String {
    return """
        ```swift
        \(example.code)
        ```
        """
}
