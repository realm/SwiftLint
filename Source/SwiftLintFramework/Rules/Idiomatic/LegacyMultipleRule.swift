import SourceKittenFramework

public struct LegacyMultipleRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_multiple",
        name: "Legacy Multiple",
        description: "Prefer using the `isMultiple(of:)` function instead of using the remainder operator (`%`).",
        kind: .idiomatic,
        minSwiftVersion: .five,
        nonTriggeringExamples: [
            "cell.contentView.backgroundColor = indexPath.row.isMultiple(of: 2) ? .gray : .white",
            "guard count.isMultiple(of: 2) else { throw DecodingError.dataCorrupted(...) }",
            "sanityCheck(bytes > 0 && bytes.isMultiple(of: 4), \"capacity must be multiple of 4 bytes\")",
            "guard let i = reversedNumbers.firstIndex(where: { $0.isMultiple(of: 2) }) else { return }",
            """
            let constant = 56
            let isMultiple = value.isMultiple(of: constant)
            """,
            """
            let constant = 56
            let secret = value % constant == 5
            """,
            "let secretValue = (value % 3) + 2"
        ],
        triggeringExamples: [
            "cell.contentView.backgroundColor = indexPath.row ↓% 2 == 0 ? .gray : .white",
            "cell.contentView.backgroundColor = indexPath.row ↓% 2 != 0 ? .gray : .white",
            "guard count ↓% 2 == 0 else { throw DecodingError.dataCorrupted(...) }",
            "sanityCheck(bytes > 0 && bytes ↓% 4 == 0, \"capacity must be multiple of 4 bytes\")",
            "guard let i = reversedNumbers.firstIndex(where: { $0 ↓% 2 == 0 }) else { return }",
            """
            let constant = 56
            let isMultiple = value ↓% constant == 0
            """
        ]
    )

    // MARK: - Rule

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "(?!\\b\\s*)%\(RegexHelpers.variableOrNumber)[=!]=\\s*0\\b"
        return file.match(pattern: pattern, excludingSyntaxKinds: SyntaxKind.commentAndStringKinds)
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.location))
            }
    }
}
