import Foundation
import SourceKittenFramework

public struct ReduceIntoRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "reduce_into",
        name: "Reduce Into",
        description: "Prefer `reduce(into:_:)` over `reduce(_:_:)` for copy-on-write types",
        kind: .performance,
        nonTriggeringExamples: [
            Example("""
            let foo = values.reduce(into: "abc") { $0 += "\\($1)" }
            """),
            Example("""
            values.reduce(into: Array<Int>()) { result, value in
                result.append(value)
            }
            """),
            Example("""
            let rows = violations.enumerated().reduce(into: "") { rows, indexAndViolation in
                rows.append(generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1))
            }
            """),
            Example("""
            zip(group, group.dropFirst()).reduce(into: []) { result, pair in
                result.append(pair.0 + pair.1)
            }
            """),
            Example("""
            let foo = values.reduce(into: [String: Int]()) { result, value in
                result["\\(value)"] = value
            }
            """),
            Example("""
            let foo = values.reduce(into: Dictionary<String, Int>.init()) { result, value in
                result["\\(value)"] = value
            }
            """),
            Example("""
            let foo = values.reduce(into: [Int](repeating: 0, count: 10)) { result, value in
                result.append(value)
            }
            """),
            Example("""
            let foo = values.reduce(MyClass()) { result, value in
                result.handleValue(value)
                return result
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            let bar = values.↓reduce("abc") { $0 + "\\($1)" }
            """),
            Example("""
            values.↓reduce(Array<Int>()) { result, value in
                result += [value]
            }
            """),
            Example("""
            let rows = violations.enumerated().↓reduce("") { rows, indexAndViolation in
                return rows + generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1)
            }
            """),
            Example("""
            zip(group, group.dropFirst()).↓reduce([]) { result, pair in
                result + [pair.0 + pair.1]
            }
            """),
            Example("""
            let foo = values.↓reduce([String: Int]()) { result, value in
                var result = result
                result["\\(value)"] = value
                return result
            }
            """),
            Example("""
            let bar = values.↓reduce(Dictionary<String, Int>.init()) { result, value in
                var result = result
                result["\\(value)"] = value
                return result
            }
            """),
            Example("""
            let bar = values.↓reduce([Int](repeating: 0, count: 10)) { result, value in
                return result + [value]
            }
            """)
        ]
    )

    private let reduceExpression = regex("(?<!\\w)reduce$")
    private let initExpression = regex("^(?:\\[.+:?.*\\]|(?:Array|Dictionary)<.+>)(?:\\.init\\(|\\().*\\)$")

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            case let nameByteRange = ByteRange(location: nameOffset, length: nameLength),
            let nameRange = file.stringView.byteRangeToNSRange(nameByteRange),
            let match = reduceExpression.firstMatch(in: file.contents, options: [], range: nameRange),
            dictionary.enclosedArguments.count == 2,
            // would otherwise equal "into"
            dictionary.enclosedArguments[0].name == nil,
            argumentIsCopyOnWriteType(dictionary.enclosedArguments[0], file: file)
        else { return [] }

        let location = Location(
            file: file,
            characterOffset: match.range.location
        )
        let violation = StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: location
        )
        return [violation]
    }

    private func argumentIsCopyOnWriteType(_ argument: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        if let substructure = argument.substructure.first,
            let kind = substructure.expressionKind {
            if kind == .array || kind == .dictionary {
                return true
            }
        }

        let contents = file.stringView
        guard let byteRange = argument.byteRange,
            let range = contents.byteRangeToNSRange(byteRange)
            else { return false }

        // Check for string literal
        let kinds = file.syntaxMap.kinds(inByteRange: byteRange)
        if kinds == [.string] {
            return true
        }

        // check for Array or Dictionary init
        let initMatch = initExpression.firstMatch(in: contents.string, options: [], range: range)
        return initMatch != nil
    }
}
