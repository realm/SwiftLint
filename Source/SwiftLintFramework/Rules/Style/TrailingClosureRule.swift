import Foundation
import SourceKittenFramework

public struct TrailingClosureRule: OptInRule, ConfigurationProviderRule {
    public var configuration = TrailingClosureConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_closure",
        name: "Trailing Closure",
        description: "Trailing closure syntax should be used whenever possible.",
        kind: .style,
        nonTriggeringExamples: [
            "foo.map { $0 + 1 }\n",
            "foo.bar()\n",
            "foo.reduce(0) { $0 + 1 }\n",
            "if let foo = bar.map({ $0 + 1 }) { }\n",
            "foo.something(param1: { $0 }, param2: { $0 + 1 })\n",
            "offsets.sorted { $0.offset < $1.offset }\n",
            "foo.something({ return 1 }())",
            "foo.something({ return $0 }(1))",
            "foo.something(0, { return 1 }())"
        ],
        triggeringExamples: [
            "↓foo.map({ $0 + 1 })\n",
            "↓foo.reduce(0, combine: { $0 + 1 })\n",
            "↓offsets.sorted(by: { $0.offset < $1.offset })\n",
            "↓foo.something(0, { $0 + 1 })\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationOffsets(for: file.structure.dictionary, file: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violationOffsets(for dictionary: [String: SourceKitRepresentable], file: File) -> [Int] {
        var results = [Int]()

        if dictionary.kind.flatMap(SwiftExpressionKind.init(rawValue:)) == .call,
            shouldBeTrailingClosure(dictionary: dictionary, file: file),
            let offset = dictionary.offset {
            results = [offset]
        }

        if let kind = dictionary.kind.flatMap(StatementKind.init), kind != .brace {
            // trailing closures are not allowed in `if`, `guard`, etc
            results += dictionary.substructure.flatMap { subDict -> [Int] in
                guard subDict.kind.flatMap(StatementKind.init) == .brace else {
                    return []
                }

                return violationOffsets(for: subDict, file: file)
            }
        } else {
            results += dictionary.substructure.flatMap { subDict in
                violationOffsets(for: subDict, file: file)
            }
        }

        return results
    }

    private func shouldBeTrailingClosure(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        func shouldTrigger() -> Bool {
            return !isAlreadyTrailingClosure(dictionary: dictionary, file: file) &&
                !isAnonymousClosureCall(dictionary: dictionary, file: file)
        }

        let arguments = dictionary.enclosedArguments

        // check if last parameter should be trailing closure
        if !configuration.onlySingleMutedParameter, !arguments.isEmpty,
            case let closureArguments = filterClosureArguments(arguments, file: file),
            closureArguments.count == 1,
            closureArguments.last?.bridge() == arguments.last?.bridge() {
            return shouldTrigger()
        }

        // check if there's only one unnamed parameter that is a closure
        if arguments.isEmpty,
            let offset = dictionary.offset,
            let totalLength = dictionary.length,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            case let start = nameOffset + nameLength,
            case let length = totalLength + offset - start,
            let range = file.contents.bridge().byteRangeToNSRange(start: start, length: length),
            let match = regex("\\s*\\(\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location {
            return shouldTrigger()
        }

        return false
    }

    private func filterClosureArguments(_ arguments: [[String: SourceKitRepresentable]],
                                        file: File) -> [[String: SourceKitRepresentable]] {
        return arguments.filter { argument in
            guard let offset = argument.bodyOffset,
                let length = argument.bodyLength,
                let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length),
                let match = regex("\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
                match.location == range.location else {
                    return false
            }

            return true
        }
    }

    private func isAlreadyTrailingClosure(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let text = file.contents.bridge().substringWithByteRange(start: offset, length: length) else {
                return false
        }

        return !text.hasSuffix(")")
    }

    private func isAnonymousClosureCall(dictionary: [String: SourceKitRepresentable],
                                        file: File) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length) else {
                return false
        }

        let pattern = regex("\\)\\s*\\)\\z")
        return pattern.numberOfMatches(in: file.contents, range: range) > 0
    }
}
