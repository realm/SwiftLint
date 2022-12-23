import Foundation
import SourceKittenFramework

struct MultilineArgumentsRule: ASTRule, OptInRule, ConfigurationProviderRule {
    var configuration = MultilineArgumentsConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "multiline_arguments",
        name: "Multiline Arguments",
        description: "Arguments should be either on the same line, or one per line",
        kind: .style,
        nonTriggeringExamples: MultilineArgumentsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineArgumentsRuleExamples.triggeringExamples
    )

    func validate(file: SwiftLintFile,
                  kind: SwiftExpressionKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            case let arguments = dictionary.enclosedArguments,
            arguments.count > 1
        else {
            return []
        }

        let wrappedArguments: [Argument] = arguments
            .enumerated()
            .compactMap { idx, argument in
                Argument(dictionary: argument, file: file, index: idx)
            }

        var violatingArguments = findViolations(in: wrappedArguments,
                                                dictionary: dictionary,
                                                file: file)

        if configuration.onlyEnforceAfterFirstClosureOnFirstLine {
            violatingArguments = removeViolationsBeforeFirstClosure(arguments: wrappedArguments,
                                                                    violations: violatingArguments,
                                                                    file: file)
        }

        return violatingArguments.map {
            return StyleViolation(ruleDescription: Self.description,
                                  severity: self.configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: $0.offset))
        }
    }

    // MARK: - Violation Logic

    private func findViolations(in arguments: [Argument],
                                dictionary: SourceKittenDictionary,
                                file: SwiftLintFile) -> [Argument] {
        guard case let contents = file.stringView,
            let nameOffset = dictionary.nameOffset,
            let (nameLine, _) = contents.lineAndCharacter(forByteOffset: nameOffset)
        else {
            return []
        }

        var visitedLines = Set<Int>()

        if configuration.firstArgumentLocation == .sameLine {
            visitedLines.insert(nameLine)
        }

        let lastIndex = arguments.count - 1

        let violations = arguments.compactMap { argument -> Argument? in
            let (line, idx) = (argument.line, argument.index)
            let (firstVisit, _) = visitedLines.insert(line)

            if idx == lastIndex && isTrailingClosure(dictionary: dictionary, file: file) {
                return nil
            } else if idx == 0 {
                switch configuration.firstArgumentLocation {
                case .anyLine: return nil
                case .nextLine: return line > nameLine ? nil : argument
                case .sameLine: return line > nameLine ? argument : nil
                }
            } else {
                return firstVisit ? nil : argument
            }
        }

        // only report violations if multiline
        return visitedLines.count > 1 ? violations : []
    }

    private func removeViolationsBeforeFirstClosure(arguments: [Argument],
                                                    violations: [Argument],
                                                    file: SwiftLintFile) -> [Argument] {
        guard let firstClosure = arguments.first(where: isClosure(in: file)),
            let firstArgument = arguments.first else {
            return violations
        }

        let violationSlice: ArraySlice<Argument> = violations
            .drop { argument in
                // drop violations if they precede the first closure,
                // if that closure is in the first line
                firstArgument.line == firstClosure.line &&
                    argument.line == firstClosure.line &&
                    argument.index <= firstClosure.index
            }

        return Array(violationSlice)
    }

    // MARK: - Syntax Helpers

    private func isTrailingClosure(dictionary: SourceKittenDictionary, file: SwiftLintFile) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            case let start = min(offset, offset + length - 1),
            case let byteRange = ByteRange(location: start, length: length),
            let text = file.stringView.substringWithByteRange(byteRange)
        else {
            return false
        }

        return !text.hasSuffix(")")
    }

    private func isClosure(in file: SwiftLintFile) -> (Argument) -> Bool {
        return { argument in
            let contents = file.stringView
            let closureMatcher = regex("^\\s*\\{")
            guard let range = contents.byteRangeToNSRange(argument.bodyRange) else {
                return false
            }

            let matches = closureMatcher.matches(in: file.contents, options: [], range: range)
            return matches.count == 1
        }
    }
}

private struct Argument {
    let offset: ByteCount
    let line: Int
    let index: Int
    let bodyRange: ByteRange

    init?(dictionary: SourceKittenDictionary, file: SwiftLintFile, index: Int) {
        guard let offset = dictionary.offset,
            let (line, _) = file.stringView.lineAndCharacter(forByteOffset: offset),
            let bodyRange = dictionary.bodyByteRange
        else {
            return nil
        }

        self.offset = offset
        self.line = line
        self.index = index
        self.bodyRange = bodyRange
    }
}
