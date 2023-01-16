import SourceKittenFramework

struct FileLengthRule: ConfigurationProviderRule {
    var configuration = FileLengthRuleConfiguration(warning: 400, error: 1000)

    init() {}

    static let description = RuleDescription(
        identifier: "file_length",
        name: "File Length",
        description: "Files should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example(repeatElement("print(\"swiftlint\")\n", count: 399).joined())
        ],
        triggeringExamples: [
            Example(repeatElement("print(\"swiftlint\")\n", count: 401).joined()),
            Example((repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined()),
            Example(repeatElement("print(\"swiftlint\")\n\n", count: 201).joined())
        ].skipWrappingInCommentTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        func lineCountWithoutComments() -> Int {
            let commentKinds = SyntaxKind.commentKinds
            let lineCount = file.syntaxKindsByLines.filter { kinds in
                return !Set(kinds).isSubset(of: commentKinds)
            }.count
            return lineCount
        }

        var lineCount = file.lines.count
        let hasViolation = configuration.severityConfiguration.params.contains {
            $0.value < lineCount
        }

        if hasViolation && configuration.ignoreCommentOnlyLines {
            lineCount = lineCountWithoutComments()
        }

        for parameter in configuration.severityConfiguration.params where lineCount > parameter.value {
            let reason = "File should contain \(configuration.severityConfiguration.warning) lines or less" +
                         (configuration.ignoreCommentOnlyLines ? " excluding comments and whitespaces" : "") +
                         ": currently contains \(lineCount)"
            return [StyleViolation(ruleDescription: Self.description,
                                   severity: parameter.severity,
                                   location: Location(file: file.path, line: file.lines.count),
                                   reason: reason)]
        }

        return []
    }
}
