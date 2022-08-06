import Foundation
import SourceKittenFramework

public struct ConditionalReturnsOnNewlineRule: ConfigurationProviderRule, OptInRule {
    public var configuration = ConditionalReturnsOnNewlineConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "conditional_returns_on_newline",
        name: "Conditional Returns on Newline",
        description: "Conditional statements should always return on the next line",
        kind: .style,
        nonTriggeringExamples: [
            Example("guard true else {\n return true\n}"),
            Example("guard true,\n let x = true else {\n return true\n}"),
            Example("if true else {\n return true\n}"),
            Example("if true,\n let x = true else {\n return true\n}"),
            Example("if textField.returnKeyType == .Next {"),
            Example("if true { // return }"),
            Example("/*if true { */ return }")
        ],
        triggeringExamples: [
            Example("↓guard true else { return }"),
            Example("↓if true { return }"),
            Example("↓if true { break } else { return }"),
            Example("↓if true { break } else {       return }"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = configuration.ifOnly ? "(if)[^\n]*return" : "(guard|if)[^\n]*return"

        return file.rangesAndTokens(matching: pattern).filter { _, tokens in
            guard let firstToken = tokens.first, let lastToken = tokens.last,
                firstToken.kind == .keyword && lastToken.kind == .keyword else {
                    return false
            }

            let searchTokens = configuration.ifOnly ? ["if"] : ["if", "guard"]
            return searchTokens.contains(file.contents(for: firstToken) ?? "") &&
                file.contents(for: lastToken) == "return"
        }.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0.0.location))
        }
    }
}
