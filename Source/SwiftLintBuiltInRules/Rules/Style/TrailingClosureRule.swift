import Foundation
import SourceKittenFramework

struct TrailingClosureRule: OptInRule, ConfigurationProviderRule {
    var configuration = TrailingClosureConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "trailing_closure",
        name: "Trailing Closure",
        description: "Trailing closure syntax should be used whenever possible",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo.map { $0 + 1 }\n"),
            Example("foo.bar()\n"),
            Example("foo.reduce(0) { $0 + 1 }\n"),
            Example("if let foo = bar.map({ $0 + 1 }) { }\n"),
            Example("foo.something(param1: { $0 }, param2: { $0 + 1 })\n"),
            Example("offsets.sorted { $0.offset < $1.offset }\n"),
            Example("foo.something({ return 1 }())"),
            Example("foo.something({ return $0 }(1))"),
            Example("foo.something(0, { return 1 }())")
        ],
        triggeringExamples: [
            Example("↓foo.map({ $0 + 1 })\n"),
            Example("↓foo.reduce(0, combine: { $0 + 1 })\n"),
            Example("↓offsets.sorted(by: { $0.offset < $1.offset })\n"),
            Example("↓foo.something(0, { $0 + 1 })\n")
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        let dict = file.structureDictionary
        return violationOffsets(for: dict, file: file).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func violationOffsets(for dictionary: SourceKittenDictionary, file: SwiftLintFile) -> [ByteCount] {
        var results = [ByteCount]()

        if dictionary.expressionKind == .call,
            shouldBeTrailingClosure(dictionary: dictionary, file: file),
            let offset = dictionary.offset {
            results = [offset]
        }

        if let kind = dictionary.statementKind, kind != .brace {
            // trailing closures are not allowed in `if`, `guard`, etc
            results += dictionary.substructure.flatMap { subDict -> [ByteCount] in
                guard subDict.statementKind == .brace else {
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

    private func shouldBeTrailingClosure(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        func shouldTrigger() -> Bool {
            return !isAlreadyTrailingClosure(dictionary: dictionary, file: file) &&
                !isAnonymousClosureCall(dictionary: dictionary, file: file)
        }

        let arguments = dictionary.enclosedArguments

        // check if last parameter should be trailing closure
        if !configuration.onlySingleMutedParameter, arguments.isNotEmpty,
            case let closureArguments = filterClosureArguments(arguments, file: file),
            closureArguments.count == 1,
            closureArguments.last?.offset == arguments.last?.offset {
            return shouldTrigger()
        }

        let argumentsCountIsExpected: Bool = {
            if SwiftVersion.current >= .fiveDotSix, arguments.count == 1,
               arguments[0].expressionKind == .argument {
                return true
            }

            return arguments.isEmpty
        }()
        // check if there's only one unnamed parameter that is a closure
        if argumentsCountIsExpected,
            let offset = dictionary.offset,
            let totalLength = dictionary.length,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            case let start = nameOffset + nameLength,
            case let length = totalLength + offset - start,
            case let byteRange = ByteRange(location: start, length: length),
            let range = file.stringView.byteRangeToNSRange(byteRange),
            let match = regex("\\s*\\(\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location {
            return shouldTrigger()
        }

        return false
    }

    private func filterClosureArguments(_ arguments: [SourceKittenDictionary],
                                        file: SwiftLintFile) -> [SourceKittenDictionary] {
        return arguments.filter { argument in
            guard let bodyByteRange = argument.bodyByteRange,
                let range = file.stringView.byteRangeToNSRange(bodyByteRange),
                let match = regex("\\s*\\{").firstMatch(in: file.contents, options: [], range: range)?.range,
                match.location == range.location
            else {
                return false
            }

            return true
        }
    }

    private func isAlreadyTrailingClosure(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let byteRange = dictionary.byteRange,
            let text = file.stringView.substringWithByteRange(byteRange)
        else {
            return false
        }

        return !text.hasSuffix(")")
    }

    private func isAnonymousClosureCall(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let byteRange = dictionary.byteRange,
            let range = file.stringView.byteRangeToNSRange(byteRange)
        else {
            return false
        }

        let pattern = regex("\\)\\s*\\)\\z")
        return pattern.numberOfMatches(in: file.contents, range: range) > 0
    }
}
