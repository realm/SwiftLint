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
        let optInRuleDocumentations = ruleDocumentations.filter { $0.isOptInRule }

        return """
            # Rule Directory

            ## Default Rules

            \(defaultRuleDocumentations
                .map { "* `\($0.ruleIdentifier)`: \($0.ruleName)" }
                .joined(separator: "\n"))

            ## Opt-In Rules

            \(optInRuleDocumentations
                .map { "* `\($0.ruleIdentifier)`: \($0.ruleName)" }
                .joined(separator: "\n"))

            """
    }

    private var swiftSyntaxDashboardContents: String {
        let linterRuleDocumentations = ruleDocumentations.filter(\.isLinterRule)
        let rulesUsingSourceKit = linterRuleDocumentations.filter(\.usesSourceKit)
        let rulesNotUsingSourceKit = linterRuleDocumentations.filter { !$0.usesSourceKit }
        let percentUsingSourceKit = Int(rulesUsingSourceKit.count * 100 / linterRuleDocumentations.count)

        return """
            # Swift Syntax Dashboard

            Efforts are actively under way to migrate most rules off SourceKit to use SwiftSyntax instead.

            Rules written using SwiftSyntax tend to be significantly faster and have fewer false positives
            than rules that use SourceKit to get source structure information.

            \(rulesUsingSourceKit.count) out of \(linterRuleDocumentations.count) (\(percentUsingSourceKit)%)
            of SwiftLint's linter rules use SourceKit.

            ## Rules Using SourceKit

            ### Enabled By Default (\(rulesUsingSourceKit.filter(\.isEnabledByDefault).count))

            \(rulesUsingSourceKit
                .filter(\.isEnabledByDefault)
                .map { "* `\($0.ruleIdentifier)`: \($0.ruleName)" }
                .joined(separator: "\n"))

            ### Opt-In (\(rulesUsingSourceKit.filter(\.isDisabledByDefault).count))

            \(rulesUsingSourceKit
                .filter(\.isDisabledByDefault)
                .map { "* `\($0.ruleIdentifier)`: \($0.ruleName)" }
                .joined(separator: "\n"))

            ## Rules Not Using SourceKit

            ### Enabled By Default (\(rulesNotUsingSourceKit.filter(\.isEnabledByDefault).count))

            \(rulesNotUsingSourceKit
                .filter(\.isEnabledByDefault)
                .map { "* `\($0.ruleIdentifier)`: \($0.ruleName)" }
                .joined(separator: "\n"))

            ### Opt-In (\(rulesNotUsingSourceKit.filter(\.isDisabledByDefault).count))

            \(rulesNotUsingSourceKit
                .filter(\.isDisabledByDefault)
                .map { "* `\($0.ruleIdentifier)`: \($0.ruleName)" }
                .joined(separator: "\n"))

            """
    }
}
