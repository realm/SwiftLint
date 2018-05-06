import Foundation
import SourceKittenFramework

internal struct ClosureEndIndentationRuleExamples {

    static let nonTriggeringExamples = [
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "   }\n",
        "[1, 2].map { $0 + 1 }\n",
        "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "}\n",
        "foo(foo: bar,\n" +
        "    options: baz) { _ in }\n",
        "someReallyLongProperty.chainingWithAnotherProperty\n" +
        "   .foo { _ in }",
        "foo(abc, 123)\n" +
        "{ _ in }\n",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })",
        "function(parameter: param,\n" +
        "         closure: { x in\n" +
        "    print(x)\n" +
        "})",
        "function(parameter: param, closure: { x in\n" +
        "        print(x)\n" +
        "    },\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "    })"
    ]

    static let triggeringExamples = [
        "SignalProducer(values: [1, 2, 3])\n" +
        "   .startWithNext { number in\n" +
        "       print(number)\n" +
        "↓}\n",
        "return match(pattern: pattern, with: [.comment]).flatMap { range in\n" +
        "   return Command(string: contents, range: range)\n" +
        "   ↓}.flatMap { command in\n" +
        "   return command.expand()\n" +
        "↓}\n",
        "function(\n" +
        "    closure: { x in\n" +
        "        print(x)\n" +
        "↓},\n" +
        "    anotherClosure: { y in\n" +
        "        print(y)\n" +
        "↓})"
    ]
}

public struct ClosureEndIndentationRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_end_indentation",
        name: "Closure End Indentation",
        description: "Closure end should have the same indentation as the line that started it.",
        kind: .style,
        nonTriggeringExamples: ClosureEndIndentationRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureEndIndentationRuleExamples.triggeringExamples
    )

    private static let notWhitespace = regex("[^\\s]")

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .call else {
            return []
        }

        return validateArguments(in: file, dictionary: dictionary) +
            validateCall(in: file, dictionary: dictionary)
    }

    private func hasTrailingClosure(in file: File,
                                    dictionary: [String: SourceKitRepresentable]) -> Bool {
        guard
            let offset = dictionary.offset,
            let length = dictionary.length,
            let text = file.contents.bridge().substringWithByteRange(start: offset, length: length)
            else {
                return false
        }

        return !text.hasSuffix(")")
    }

    private func validateCall(in file: File,
                              dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let contents = file.contents.bridge()
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let bodyLength = dictionary.bodyLength,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            bodyLength > 0,
            case let endOffset = offset + length - 1,
            contents.substringWithByteRange(start: endOffset, length: 1) == "}",
            let startOffset = startOffset(forDictionary: dictionary, file: file),
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: startOffset),
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            case let nameEndPosition = nameOffset + nameLength,
            let (bodyOffsetLine, _) = contents.lineAndCharacter(forByteOffset: nameEndPosition),
            startLine != endLine, bodyOffsetLine != endLine,
            !containsSingleLineClosure(dictionary: dictionary, endPosition: endOffset, file: file) else {
                return []
        }

        let range = file.lines[startLine - 1].range
        let regex = ClosureEndIndentationRule.notWhitespace
        let actual = endPosition - 1
        guard let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            case let expected = match.location - range.location,
            expected != actual  else {
                return []
        }

        let reason = "Closure end should have the same indentation as the line that started it. " +
                     "Expected \(expected), got \(actual)."
        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: endOffset),
                           reason: reason)
        ]
    }

    func validateArguments(in file: File,
                           dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard isFirstArgumentOnNewline(dictionary, file: file) else {
            return []
        }

        var closureArguments = filterClosureArguments(dictionary.enclosedArguments, file: file)

        if hasTrailingClosure(in: file, dictionary: dictionary), !closureArguments.isEmpty {
            closureArguments.removeLast()
        }

        let argumentViolations = closureArguments.flatMap { dictionary in
            return validateClosureArgument(in: file, dictionary: dictionary)
        }

        return argumentViolations
    }

    private func validateClosureArgument(in file: File,
                                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        let contents = file.contents.bridge()
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let bodyLength = dictionary.bodyLength,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            bodyLength > 0,
            case let endOffset = offset + length - 1,
            contents.substringWithByteRange(start: endOffset, length: 1) == "}",
            let startOffset = dictionary.offset,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: startOffset),
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            case let nameEndPosition = nameOffset + nameLength,
            let (bodyOffsetLine, _) = contents.lineAndCharacter(forByteOffset: nameEndPosition),
            startLine != endLine, bodyOffsetLine != endLine,
            !isSingleLineClosure(dictionary: dictionary, endPosition: endOffset, file: file) else {
                return []
        }

        let range = file.lines[startLine - 1].range
        let regex = ClosureEndIndentationRule.notWhitespace
        let actual = endPosition - 1
        guard let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            case let expected = match.location - range.location,
            expected != actual  else {
                return []
        }

        let reason = "Closure end should have the same indentation as the line that started it. " +
                     "Expected \(expected), got \(actual)."
        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: endOffset),
                           reason: reason)
        ]
    }

    private func startOffset(forDictionary dictionary: [String: SourceKitRepresentable], file: File) -> Int? {
        guard let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength else {
            return nil
        }

        let newLineRegex = regex("\n(\\s*\\}?\\.)")
        let contents = file.contents.bridge()
        guard let range = contents.byteRangeToNSRange(start: nameOffset, length: nameLength),
            let match = newLineRegex.matches(in: file.contents, options: [],
                                             range: range).last?.range(at: 1),
            let methodByteRange = contents.NSRangeToByteRange(start: match.location,
                                                              length: match.length) else {
            return nameOffset
        }

        return methodByteRange.location
    }

    private func isSingleLineClosure(dictionary: [String: SourceKitRepresentable],
                                     endPosition: Int, file: File) -> Bool {
        let contents = file.contents.bridge()

        guard let start = dictionary.bodyOffset,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: start),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: endPosition) else {
                return false
        }

        return startLine == endLine
    }

    private func containsSingleLineClosure(dictionary: [String: SourceKitRepresentable],
                                           endPosition: Int, file: File) -> Bool {
        let contents = file.contents.bridge()

        guard let closure = trailingClosure(dictionary: dictionary, file: file),
            let start = closure.bodyOffset,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: start),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: endPosition) else {
                return false
        }

        return startLine == endLine
    }

    private func trailingClosure(dictionary: [String: SourceKitRepresentable],
                                 file: File) -> [String: SourceKitRepresentable]? {
        let arguments = dictionary.enclosedArguments
        let closureArguments = filterClosureArguments(arguments, file: file)

        if closureArguments.count == 1,
            closureArguments.last?.bridge() == arguments.last?.bridge() {
            return closureArguments.last
        }

        return nil
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

    private func isFirstArgumentOnNewline(_ dictionary: [String: SourceKitRepresentable],
                                          file: File) -> Bool {
        guard
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let firstArgument = dictionary.enclosedArguments.first,
            let firstArgumentOffset = firstArgument.offset,
            case let offset = nameOffset + nameLength,
            case let length = firstArgumentOffset - offset,
            let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length),
            let match = regex("\\(\\s*\\n\\s*").firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location else {
                return false
        }

        return true
    }
}
