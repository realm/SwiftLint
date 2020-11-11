import Foundation
import SourceKittenFramework

public struct RedundantBoolComparisonRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public init() {}

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "redundant_bool_comparison",
        name: "Redundant Bool Comparison",
        description: """
            The usage of `==` or `!=` operators for checking if the Bool value is `true` or `false` \
            is discouraged in favor of using the Bool value itself or the one with negation operator
            """,
        kind: .performance,
        nonTriggeringExamples: [
            Example("""
            var isEnabled = true
            if isEnabled { /* do stuff */ }
            """),
            Example("""
            let value = "true"
            if value == "true" { /* do stuff */ }
            """),
            Example("""
            var isEnabled = true
            // check if isEnabled == true
            if isEnabled { /* do stuff */ }
            """),
            Example("""
            enum Success {
                case `true`
                case `false`
            }

            let success: Success = .true
            if success == .true { /* do stuff */ }
            """)
        ],
        triggeringExamples: [
            Example("""
            var isEnabled = true
            if isEnabled ↓== true { /* do stuff */ }
            """),
            Example("""
            // don't forget the Yoda notation:
            var isEnabled = true
            if ↓true == isEnabled, isEnabled ↓== true { /* do stuff */ }
            """),
            Example("""
            var isEnabled = true
            if  ↓!true != isEnabled { /* do stuff */ }
            """),
            Example("""
            var isEnabled = true
            if isEnabled↓!=false { /* do stuff */ }
            """),
            Example("""
            var isEnabled = true
            if isEnabled ↓==       true { /* do stuff */ }
            """),
            Example("""
            var isEnabled = true
            if isEnabled ↓==


                true { /* do stuff */ }
            """),
            Example("""
            if ↓true == true { /* do stuff */ }
            """)
        ])

    private let conditionExpressionKind = "source.lang.swift.structure.elem.condition_expr"

    private let pattern =
        "(=|!)=" +          // equal or not equal operator
        "\\s*" +            // any number of whitespace characters
        "!?(true|false)" +  // true or false with possible negating operator
        "|" +               // and the same in reverse order, Yoda notation to cover
        "!?(true|false)" +
        "\\s*" +
        "(=|!)="

    public func validate(
        file: SwiftLintFile,
        kind: StatementKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {
        guard kind == .if else { return [] }

        let conditionExpressions = dictionary.elements.filter { $0.kind == conditionExpressionKind }

        let totalViolations = conditionExpressions.flatMap { expression -> [StyleViolation] in
            guard
                let offset = expression.offset,
                let lenght = expression.length
            else {
                return []
            }

            let byteRange = ByteRange(location: offset, length: lenght)
            let range = file.stringView.byteRangeToNSRange(byteRange)
            let matches = file.match(pattern: pattern, with: [.keyword], range: range)
            let violations: [StyleViolation] = matches.map { match in
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: match.location))
            }

            return violations
        }

        return totalViolations
    }
}
