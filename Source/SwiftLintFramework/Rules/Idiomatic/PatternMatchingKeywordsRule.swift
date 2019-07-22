import Foundation
import SourceKittenFramework

public struct PatternMatchingKeywordsRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = PatternMatchingKeywordsRuleConfiguration(maxDeclarations: 1)

    public init() {}

    public static let description = RuleDescription(
        identifier: "pattern_matching_keywords",
        name: "Pattern Matching Keywords",
        description: "Combine multiple pattern matching bindings by moving keywords out of tuples.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "default",
            "case 1",
            "case bar",
            "case let (x, y)",
            "case .foo(let x)",
            "case let .foo(x, y)",
            "case .foo(let x), .bar(let x)",
            "case .foo(let x, var y)",
            "case var (x, y)",
            "case .foo(var x)",
            "case var .foo(x, y)"
        ].map(wrapInSwitch),
        triggeringExamples: [
            "case (↓let x,  ↓let y)",
            "case .foo(↓let x, ↓let y)",
            "case (.yamlParsing(↓let x), .yamlParsing(↓let y))",
            "case (↓var x,  ↓var y)",
            "case .foo(↓var x, ↓var y)",
            "case (.yamlParsing(↓var x), .yamlParsing(↓var y))",
            "case .foo(↓let x, (↓let y, ↓let z))",
        ].map(wrapInSwitch)
    )

    public func validate(file: File, kind: StatementKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .case else {
            return []
        }

        let contents = file.contents.bridge()
        return dictionary.elements.flatMap { subDictionary -> [StyleViolation] in
            guard subDictionary.kind == "source.lang.swift.structure.elem.pattern",
                let offset = subDictionary.offset,
                let length = subDictionary.length,
                let caseRange = contents.byteRangeToNSRange(start: offset, length: length) else {
                    return []
            }

            let parametersRanges = file.match(pattern: "\\([^\\)]*\\)", range: caseRange).map { $0.0 }

            var letMatches: [NSRange] = []
            var varMatches: [NSRange] = []
            for range in parametersRanges {
                letMatches += file.match(pattern: "\\blet\\b", with: [.keyword], range: range)
                varMatches += file.match(pattern: "\\bvar\\b", with: [.keyword], range: range)
            }

            if !letMatches.isEmpty && !varMatches.isEmpty {
                return []
            }

            guard letMatches.count > configuration.maxDeclarations ||
                varMatches.count > configuration.maxDeclarations else {
                return []
            }

            return (letMatches + varMatches).map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severityConfiguration.severity,
                               location: Location(file: file, characterOffset: $0.location))
            }
        }
    }
}

private func wrapInSwitch(_ str: String) -> String {
    return  "switch foo {\n" +
            "    \(str): break\n" +
            "}"
}
