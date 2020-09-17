import Foundation
import SourceKittenFramework

public struct YodaConditionRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let regularExpression = regex(
        "(?<!" +                      // Starting negative lookbehind
        "(" +                         // First capturing group
        "\\+|-|\\*|\\/|%|\\?" +       // One of the operators
        ")" +                         // Ending negative lookbehind
        ")" +                         // End first capturing group
        "\\s+" +                      // Starting with whitespace
        "(" +                         // Second capturing group
        "(?:\\\"[\\\"\\w\\ ]+\")" +   // Multiple words between quotes
        "|" +                         // OR
        "(?:\\d+" +                   // Number of digits
        "(?:\\.\\d*)?)" +             // Optionally followed by a dot and any number digits
        "|" +                         // OR
        "(nil)" +                     // `nil` value
        ")" +                         // End second capturing group
        "\\s+" +                      // Followed by whitespace
        "(" +                         // Third capturing group
        "==|!=|>|<|>=|<=" +           // One of comparison operators
        ")" +                         // End third capturing group
        "\\s+" +                      // Followed by whitespace
        "(" +                         // Fourth capturing group
        "\\w+" +                      // Number of words
        ")"                           // End fourth capturing group
    )
    private let observedStatements: Set<StatementKind> = [.if, .guard, .repeatWhile, .while]

    public static let description = RuleDescription(
        identifier: "yoda_condition",
        name: "Yoda condition rule",
        description: "The variable should be placed on the left, the constant on the right of a comparison operator.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("if foo == 42 {}\n"),
            Example("if foo <= 42.42 {}\n"),
            Example("guard foo >= 42 else { return }\n"),
            Example("guard foo != \"str str\" else { return }"),
            Example("while foo < 10 { }\n"),
            Example("while foo > 1 { }\n"),
            Example("while foo + 1 == 2 {}"),
            Example("if optionalValue?.property ?? 0 == 2 {}"),
            Example("if foo == nil {}")
        ],
        triggeringExamples: [
            Example("↓if 42 == foo {}\n"),
            Example("↓if 42.42 >= foo {}\n"),
            Example("↓guard 42 <= foo else { return }\n"),
            Example("↓guard \"str str\" != foo else { return }"),
            Example("↓while 10 > foo { }"),
            Example("↓while 1 < foo { }"),
            Example("↓if nil == foo {}")
        ])

    public func validate(file: SwiftLintFile,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard observedStatements.contains(kind), let offset = dictionary.offset else {
            return []
        }

        let matches = file.lines.filter({ $0.byteRange.contains(offset) }).reduce(into: []) { matches, line in
            let range = line.content.fullNSRange
            let lineMatches = YodaConditionRule.regularExpression.matches(in: line.content, options: [], range: range)
            matches.append(contentsOf: lineMatches)
        }

        return matches.map { _ -> StyleViolation in
            return StyleViolation(ruleDescription: Self.description, severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset))
        }
    }
}
