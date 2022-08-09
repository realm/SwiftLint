import Foundation
import SourceKittenFramework

public struct PatternMatchingKeywordsRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "pattern_matching_keywords",
        name: "Pattern Matching Keywords",
        description: "Combine multiple pattern matching bindings by moving keywords out of tuples.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("default"),
            Example("case 1"),
            Example("case bar"),
            Example("case let (x, y)"),
            Example("case .foo(let x)"),
            Example("case let .foo(x, y)"),
            Example("case .foo(let x), .bar(let x)"),
            Example("case .foo(let x, var y)"),
            Example("case var (x, y)"),
            Example("case .foo(var x)"),
            Example("case var .foo(x, y)")
        ].map(wrapInSwitch),
        triggeringExamples: [
            Example("case (↓let x,  ↓let y)"),
            Example("case .foo(↓let x, ↓let y)"),
            Example("case (.yamlParsing(↓let x), .yamlParsing(↓let y))"),
            Example("case (↓var x,  ↓var y)"),
            Example("case .foo(↓var x, ↓var y)"),
            Example("case (.yamlParsing(↓var x), .yamlParsing(↓var y))")
        ].map(wrapInSwitch)
    )

    public func validate(file: SwiftLintFile, kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .case else {
            return []
        }

        let contents = file.stringView
        return dictionary.elements.flatMap { subDictionary -> [StyleViolation] in
            guard subDictionary.kind == "source.lang.swift.structure.elem.pattern",
                let caseByteRange = subDictionary.byteRange,
                let caseRange = contents.byteRangeToNSRange(caseByteRange)
            else {
                return []
            }

            let letMatches = file.match(pattern: "\\blet\\b", with: [.keyword], range: caseRange)
            let varMatches = file.match(pattern: "\\bvar\\b", with: [.keyword], range: caseRange)

            if letMatches.isNotEmpty && varMatches.isNotEmpty {
                return []
            }

            guard letMatches.count > 1 || varMatches.count > 1 else {
                return []
            }

            return (letMatches + varMatches).map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.location))
            }
        }
    }
}

private func wrapInSwitch(_ example: Example) -> Example {
    return example.with(code: """
        switch foo {
            \(example.code): break
        }
        """)
}
