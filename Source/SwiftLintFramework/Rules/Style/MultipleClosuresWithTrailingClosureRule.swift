import Foundation
import SourceKittenFramework

public struct MultipleClosuresWithTrailingClosureRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiple_closures_with_trailing_closure",
        name: "Multiple Closures with Trailing Closure",
        description: "Trailing closure syntax should not be used when passing more than one closure argument.",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo.map { $0 + 1 }\n"),
            Example("foo.reduce(0) { $0 + $1 }\n"),
            Example("if let foo = bar.map({ $0 + 1 }) {\n\n}\n"),
            Example("foo.something(param1: { $0 }, param2: { $0 + 1 })\n"),
            Example("""
            UIView.animate(withDuration: 1.0) {
                someView.alpha = 0.0
            }
            """)
        ],
        triggeringExamples: [
            Example("foo.something(param1: { $0 }) ↓{ $0 + 1 }"),
            Example("""
            UIView.animate(withDuration: 1.0, animations: {
                someView.alpha = 0.0
            }) ↓{ _ in
                someView.removeFromSuperview()
            }
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call,
            case let arguments = dictionary.enclosedArguments,
            arguments.count > 1,
            let lastArgument = arguments.last,
            isTrailingClosure(argument: lastArgument, call: dictionary),
            case let closureArguments = arguments.filterClosures(file: file),
            closureArguments.count > 1,
            let trailingClosureOffset = lastArgument.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: trailingClosureOffset))
        ]
    }

    private func isTrailingClosure(argument: SourceKittenDictionary,
                                   call: SourceKittenDictionary) -> Bool {
        guard let callOffset = call.offset,
            let callLength = call.length,
            let argumentOffset = argument.offset,
            let argumentLength = argument.length else {
            return false
        }

        return callOffset + callLength == argumentOffset + argumentLength
    }
}

private extension Array where Element == SourceKittenDictionary {
    func filterClosures(file: SwiftLintFile) -> [SourceKittenDictionary] {
        if SwiftVersion.current < .fourDotTwo {
            return filter { argument in
                guard let bodyByteRange = argument.bodyByteRange,
                    let range = file.stringView.byteRangeToNSRange(bodyByteRange),
                    let match = regex("^\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
                    match.location == range.location
                else {
                    return false
                }

                return true
            }
        } else {
            return filter { argument in
                return argument.substructure.contains(where: { dictionary in
                    dictionary.expressionKind == .closure
                })
            }
        }
    }
}
