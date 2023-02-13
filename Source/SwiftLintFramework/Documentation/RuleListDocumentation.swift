import Foundation

/// User-facing documentation for a SwiftLint RuleList.
public struct RuleListDocumentation {
    private let ruleDocumentations: [RuleDocumentation]

    /// Creates a RuleListDocumentation instance from a RuleList.
    ///
    /// - parameter list: A RuleList to document.
    public init(_ list: RuleList) {
        ruleDocumentations = list.list
            .sorted { $0.0 < $1.0 }
            .map { RuleDocumentation($0.value) }
    }

    /// Write the rule list documentation as markdown files to the specified directory.
    ///
    /// - parameter url: Local URL for directory where the markdown files for this documentation should be saved.
    ///
    /// - throws: Throws if the files could not be written to.
    public func write(to url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        func write(_ text: String, toFile file: String) throws {
            try text.write(to: url.appendingPathComponent(file), atomically: false, encoding: .utf8)
        }
        try write(indexContents, toFile: "Rule Directory.md")
        try write(swiftSyntaxDashboardContents, toFile: "Swift Syntax Dashboard.md")
        for doc in ruleDocumentations {
            try write(doc.fileContents, toFile: doc.fileName)
        }
    }

    // MARK: - Private

    private var indexContents: String {
        let defaultRuleDocumentations = ruleDocumentations.filter { !$0.isOptInRule }
        let optInRuleDocumentations = ruleDocumentations.filter { $0.isOptInRule && !$0.isAnalyzerRule }
        let analyzerRuleDocumentations = ruleDocumentations.filter { $0.isAnalyzerRule }

        return """
            # Rule Directory

            ## Default Rules

            \(defaultRuleDocumentations.map(makeListEntry).joined(separator: "\n"))

            ## Opt-in Rules

            \(optInRuleDocumentations.map(makeListEntry).joined(separator: "\n"))

            ## Analyzer Rules

            \(analyzerRuleDocumentations.map(makeListEntry).joined(separator: "\n"))

            """
    }

    private func makeListEntry(from rule: RuleDocumentation) -> String {
        "* [`\(rule.ruleIdentifier)`](\(rule.ruleIdentifier).md): \(rule.ruleName)"
    }

    private var swiftSyntaxDashboardContents: String {
        let linterRuleDocumentations = ruleDocumentations.filter(\.isLinterRule)
        let rulesUsingSourceKit = linterRuleDocumentations.filter(\.usesSourceKit)
        let rulesNotUsingSourceKit = linterRuleDocumentations.filter { !$0.usesSourceKit }
        let percentUsingSourceKit = Int(rulesUsingSourceKit.count * 100 / linterRuleDocumentations.count)
        let enabledSourceKitRules = rulesUsingSourceKit.filter(\.isEnabledByDefault)
        let disabledSourceKitRules = rulesUsingSourceKit.filter(\.isDisabledByDefault)
        let enabledSourceKitFreeRules = rulesNotUsingSourceKit.filter(\.isEnabledByDefault)
        let disabledSourceKitFreeRules = rulesNotUsingSourceKit.filter(\.isDisabledByDefault)

        return """
            # Swift Syntax Dashboard

            Efforts are actively under way to migrate most rules off SourceKit to use SwiftSyntax instead.

            Rules written using SwiftSyntax tend to be significantly faster and have fewer false positives
            than rules that use SourceKit to get source structure information.

            \(rulesUsingSourceKit.count) out of \(linterRuleDocumentations.count) (\(percentUsingSourceKit)%)
            of SwiftLint's linter rules use SourceKit.

            ## Rules Using SourceKit

            ### Default Rules (\(enabledSourceKitRules.count))

            \(enabledSourceKitRules.map(makeListEntry).joined(separator: "\n"))

            ### Opt-in Rules (\(disabledSourceKitRules.count))

            \(disabledSourceKitRules.map(makeListEntry).joined(separator: "\n"))

            ## Rules not Using SourceKit

            ### Default Rules (\(enabledSourceKitFreeRules.count))

            \(enabledSourceKitFreeRules.map(makeListEntry).joined(separator: "\n"))

            ### Opt-in Rules (\(disabledSourceKitFreeRules.count))

            \(disabledSourceKitFreeRules.map(makeListEntry).joined(separator: "\n"))

            """
    }
}
