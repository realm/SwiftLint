import SourceKittenFramework

public struct ReduceIntoRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "reduce_into",
        name: "Reduce Into",
        description: "Prefer `reduce(into:_:)` over `reduce(_:_:)`",
        kind: .performance,
        minSwiftVersion: .three,
        nonTriggeringExamples: [
            "let result = values.reduce(into: 0, +=)",
            "values.reduce(into: \"\") { $0.append(\"\\($1)\") }\n",
            "values.reduce(into: initial) { $0 *= $1 }\n",
            """
            let result = values.reduce(into: 0) { result, value in
                result += value
            }
            """,
            """
            zip(group, group.dropFirst()).reduce(into: []) { result, pair in
                result.append(pair.0 + pair.1)
            }
            """
        ],
        triggeringExamples: [
            "let result = values.↓reduce(0, +)\n",
            "values.↓reduce(\"\") { $0 + \"\\($1)\" }\n",
            "values.↓reduce(initial) { $0 * $1 }\n",
            """
            let result = values.↓reduce(0) { result, value in
                result + value
            }
            """,
            """
            zip(group, group.dropFirst()).↓reduce([]) { result, pair in
                result + [pair.0 + pair.1]
            }
            """
        ]
    )

    private let reduceExpression = regex("(?<!\\w)reduce$")

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let name = dictionary.name,
            let match = reduceExpression.firstMatch(in: name, options: [], range: name.fullNSRange),
            dictionary.enclosedArguments.count == 2,
            // would otherwise equal "into"
            dictionary.enclosedArguments[0].name == nil,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let nameRange = file.contents.bridge().byteRangeToNSRange(start: nameOffset, length: nameLength)
            else { return [] }

        let location = Location(
            file: file,
            characterOffset: nameRange.location + match.range.location
        )
        let violation = StyleViolation(
            ruleDescription: type(of: self).description,
            severity: configuration.severity,
            location: location
        )
        return [violation]
    }
}
