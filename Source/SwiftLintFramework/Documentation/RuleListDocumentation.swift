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
}
