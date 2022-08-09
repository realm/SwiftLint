import SourceKittenFramework

public struct ClosureBodyLengthRule: OptInRule, ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityLevelsConfiguration(warning: 20, error: 100)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_body_length",
        name: "Closure Body Length",
        description: "Closure bodies should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: ClosureBodyLengthRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureBodyLengthRuleExamples.triggeringExamples
    )

    // MARK: - ASTRule

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .closure,
            let offset = dictionary.offset,
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            let startLine = file.stringView.lineAndCharacter(forByteOffset: bodyOffset)?.line,
            let endLine = file.stringView.lineAndCharacter(forByteOffset: bodyOffset + bodyLength)?.line
            else {
                return []
        }

        return configuration.params.compactMap { parameter in
            let (exceeds, lineCount) = file.exceedsLineCountExcludingCommentsAndWhitespace(startLine,
                                                                                           endLine,
                                                                                           parameter.value)

            guard exceeds else { return nil }

            let reason = "Closure body should span \(configuration.warning) lines or less "
                + "excluding comments and whitespace: currently spans \(lineCount) lines"

            return StyleViolation(ruleDescription: Self.description,
                                  severity: parameter.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: reason)
        }
    }
}
