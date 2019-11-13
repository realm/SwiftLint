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
            "if foo == 42 {}\n",
            "if foo <= 42.42 {}\n",
            "guard foo >= 42 else { return }\n",
            "guard foo != \"str str\" else { return }",
            "while foo < 10 { }\n",
            "while foo > 1 { }\n",
            "while foo + 1 == 2",
            "if optionalValue?.property ?? 0 == 2",
            "if foo == nil"
        ],
        triggeringExamples: [
            "↓if 42 == foo {}\n",
            "↓if 42.42 >= foo {}\n",
            "↓guard 42 <= foo else { return }\n",
            "↓guard \"str str\" != foo else { return }",
            "↓while 10 > foo { }",
            "↓while 1 < foo { }",
            "↓if nil == foo"
        ])

    public func validate(file: SwiftLintFile,
                         kind: StatementKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard observedStatements.contains(kind),
              let offset = dictionary.offset,
              let length = dictionary.length
          else {
                return []
        }

        let matches = file.lines.filter({ $0.byteRange.contains(offset) }).reduce(into: []) { matches, line in
            let range = NSRange(location: 0, length: line.content.bridge().length)
            let lineMatches = YodaConditionRule.regularExpression.matches(in: line.content, options: [], range: range)
            matches.append(contentsOf: lineMatches)
        }

        return matches.map { _ -> StyleViolation in
            let characterOffset = startOffset(of: offset, with: length, in: file)
            let location = Location(file: file, characterOffset: characterOffset)
            return StyleViolation(ruleDescription: type(of: self).description, severity: configuration.severity,
                                  location: location)
        }
    }

    private func startOffset(of offset: Int, with length: Int, in file: SwiftLintFile) -> Int {
        let range = file.linesContainer.byteRangeToNSRange(start: offset, length: length)
        return range?.location ?? offset
    }
}
