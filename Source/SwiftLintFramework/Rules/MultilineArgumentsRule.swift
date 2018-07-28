import Foundation
import SourceKittenFramework

public struct MultilineArgumentsRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = MultilineArgumentsConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_arguments",
        name: "Multiline Arguments",
        description: "Arguments should be either on the same line, or one per line.",
        kind: .style,
        nonTriggeringExamples: MultilineArgumentsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineArgumentsRuleExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            case let arguments = dictionary.enclosedArguments,
            arguments.count > 1 else {
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
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: self.configuration.severityConfiguration.severity,
                                  location: Location(file: file, byteOffset: $0.offset))
        }
    }

    // MARK: - Violation Logic

    private func findViolations(in arguments: [Argument],
                                dictionary: [String: SourceKitRepresentable],
                                file: File) -> [Argument] {
        guard case let contents = file.contents.bridge(),
            let nameOffset = dictionary.nameOffset,
            let (nameLine, _) = contents.lineAndCharacter(forByteOffset: nameOffset) else {
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
                                                    file: File) -> [Argument] {
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

    private func isTrailingClosure(dictionary: [String: SourceKitRepresentable], file: File) -> Bool {
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            case let start = min(offset, offset + length - 1),
            let text = file.contents.bridge().substringWithByteRange(start: start, length: length) else {
                return false
        }

        return !text.hasSuffix(")")
    }

    private func isClosure(in file: File) -> (Argument) -> Bool {
        return { argument in
            let contents = file.contents.bridge()
            let closureMatcher = regex("^\\s*\\{")
            guard let range = contents.byteRangeToNSRange(start: argument.bodyOffset,
                                                          length: argument.bodyLength),
                case let matches = closureMatcher.matches(in: file.contents,
                                                          options: [],
                                                          range: range) else {
                return false
            }

            return matches.count == 1
        }
    }
}

private struct Argument {
    let offset: Int
    let line: Int
    let index: Int
    let bodyOffset: Int
    let bodyLength: Int

    init?(dictionary: [String: SourceKitRepresentable], file: File, index: Int) {
        guard let offset = dictionary.offset,
            let (line, _) = file.contents.bridge().lineAndCharacter(forByteOffset: offset),
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength else {
            return nil
        }

        self.offset = offset
        self.line = line
        self.index = index
        self.bodyOffset = bodyOffset
        self.bodyLength = bodyLength
    }
}
