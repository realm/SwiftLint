import Foundation
import SourceKittenFramework

public struct ImplicitReturnRule: ConfigurationProviderRule, SubstitutionCorrectableRule, OptInRule,
                                  AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures.",
        kind: .style,
        nonTriggeringExamples: [
            "foo.map { $0 + 1 }",
            "foo.map({ $0 + 1 })",
            "foo.map { value in value + 1 }",
            "func foo() -> Int {\n  return 0\n}",
            "if foo {\n  return 0\n}",
            "var foo: Bool { return true }"
        ],
        triggeringExamples: [
            "foo.map { value in\n  ↓return value + 1\n}",
            "foo.map {\n  ↓return $0 + 1\n}",
            "foo.map({ ↓return $0 + 1})",
            """
            [1, 2].first(where: {
                ↓return true
            })
            """
        ],
        corrections: [
            "foo.map { value in\n  ↓return value + 1\n}": "foo.map { value in\n  value + 1\n}",
            "foo.map {\n  ↓return $0 + 1\n}": "foo.map {\n  $0 + 1\n}",
            "foo.map({ ↓return $0 + 1})": "foo.map({ $0 + 1})",
            """
            [1, 2].first(where: {
                ↓return true
            })
            """:
            """
            [1, 2].first(where: {
                true
            })
            """
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(in: file).compactMap {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String) {
        return (violationRange, "")
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let pattern = "(?:\\bin|\\{)\\s+(return\\s+)"
        let contents = file.linesContainer

        return file.matchesAndSyntaxKinds(matching: pattern).compactMap { result, kinds in
            let range = result.range
            guard kinds == [.keyword, .keyword] || kinds == [.keyword],
                let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                            length: range.length),
                let outerKindString = file.structureDictionary.kinds(forByteOffset: byteRange.location).last?.kind,
                let outerKind = SwiftExpressionKind(rawValue: outerKindString),
                [.call, .argument, .closure].contains(outerKind) else {
                    return nil
            }

            return result.range(at: 1)
        }
    }
}
