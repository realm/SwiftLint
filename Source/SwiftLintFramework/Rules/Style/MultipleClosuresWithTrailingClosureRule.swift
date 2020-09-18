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
            """),
            Example("foo.method { print(0) } arg2: { print(1) }"),
            Example("foo.methodWithParenArgs((0, 1), arg2: (0, 1, 2)) { $0 } arg4: { $0 }")
        ],
        triggeringExamples: [
            Example("foo.something(param1: { $0 }) ↓{ $0 + 1 }"),
            Example("""
            UIView.animate(withDuration: 1.0, animations: {
                someView.alpha = 0.0
            }) ↓{ _ in
                someView.removeFromSuperview()
            }
            """),
            Example("foo.multipleTrailing(arg1: { $0 }) { $0 } arg3: { $0 }"),
            Example("foo.methodWithParenArgs(param1: { $0 }, param2: (0, 1), (0, 1)) { $0 }")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call,
            case let arguments = dictionary.enclosedArguments,
            case let closureArguments = arguments.filterClosures(file: file),
            // Any violations must have at least one closure argument.
            closureArguments.isEmpty == false,
            // If there is no closing paren (e.g. `foo { ... }`), there is no violation.
            let closingParenOffset = dictionary.closingParenLocation(file: file),
            // Find all trailing closures.
            case let trailingClosureArguments = closureArguments.filter({
                isTrailingClosure(argument: $0, closingParenOffset: closingParenOffset)
            }),
            // If there are no trailing closures, there is no violation.
            trailingClosureArguments.isEmpty == false,
            // If all closure arguments are trailing closures, there is no violation
            trailingClosureArguments.count != closureArguments.count,
            let firstTrailingClosureOffset = trailingClosureArguments.first?.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: firstTrailingClosureOffset))
        ]
    }

    // A closure is 'trailing' if it appears outside the closing paren.
    private func isTrailingClosure(argument: SourceKittenDictionary,
                                   closingParenOffset: ByteCount) -> Bool {
        guard let argOffset = argument.offset else {
            return false
        }

        return argOffset > closingParenOffset
    }
}

private extension SourceKittenDictionary {
    func closingParenLocation(file: SwiftLintFile) -> ByteCount? {
        guard self.expressionKind == .call,
              case let arguments = self.enclosedArguments,
              arguments.isEmpty == false else {
            return nil
        }

        func rangeBetween(_ expr1: SourceKittenDictionary, and expr2: SourceKittenDictionary) -> ByteRange? {
            guard let offset1 = expr1.offset,
                  let length1 = expr1.length,
                  let offset2 = expr2.offset,
                  case let end1 = offset1 + length1,
                  end1 <= offset2 else {
                return nil
            }

            return ByteRange(location: end1, length: offset2 - end1)
        }

        var searchRanges: [ByteRange] = []
        for index in arguments.indices.dropLast() {
            let currentArg = arguments[index]
            let nextArg = arguments[index + 1]
            if let range = rangeBetween(currentArg, and: nextArg) {
                searchRanges.append(range)
            }
        }

        if let lastOffset = arguments.last?.offset,
           let lastLength = arguments.last?.length,
           let callOffset = self.offset,
           let callLength = self.length,
           case let lastEnd = lastOffset + lastLength,
           case let callEnd = callOffset + callLength,
           lastEnd <= callEnd {
            searchRanges.append(ByteRange(location: lastEnd, length: callEnd - lastEnd))
        }

        for byteRange in searchRanges {
            if let range = file.stringView.byteRangeToNSRange(byteRange),
               let match = regex("^\\s*\\)").firstMatch(in: file.contents, options: [], range: range)?.range {
                return file.stringView.byteOffset(fromLocation: match.location)
            }
        }

        return nil
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
