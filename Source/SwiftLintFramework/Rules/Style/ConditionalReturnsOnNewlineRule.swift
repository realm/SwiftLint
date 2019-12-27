import Foundation
import SourceKittenFramework

public struct ConditionalReturnsOnNewlineRule: ConfigurationProviderRule, Rule, OptInRule {
    public var configuration = ConditionalReturnsOnNewlineConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "conditional_returns_on_newline",
        name: "Conditional Returns on Newline",
        description: "Conditional statements should always return on the next line",
        kind: .style,
        nonTriggeringExamples: [
            "guard true else {\n return true\n}",
            "guard true,\n let x = true else {\n return true\n}",
            "if true else {\n return true\n}",
            "if true,\n let x = true else {\n return true\n}",
            "if textField.returnKeyType == .Next {",
            "if true { // return }",
            "/*if true { */ return }"
        ],
        triggeringExamples: [
            "↓guard true else { return }",
            "↓if true { return }",
            "↓if true { break } else { return }",
            "↓if true { break } else {       return }",
            "↓if true { return \"YES\" } else { return \"NO\" }"
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
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: $0.0.location))
        }
    }
}
