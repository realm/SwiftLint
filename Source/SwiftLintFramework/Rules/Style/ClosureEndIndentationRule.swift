import Foundation
import SourceKittenFramework

struct ClosureEndIndentationRule: Rule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "closure_end_indentation",
        name: "Closure End Indentation",
        description: "Closure end should have the same indentation as the line that started it.",
        kind: .style,
        nonTriggeringExamples: ClosureEndIndentationRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureEndIndentationRuleExamples.triggeringExamples,
        corrections: ClosureEndIndentationRuleExamples.corrections
    )

    fileprivate static let notWhitespace = regex("[^\\s]")

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violations(in: file).map { violation in
            return styleViolation(for: violation, in: file)
        }
    }

    private func styleViolation(for violation: Violation, in file: SwiftLintFile) -> StyleViolation {
        let reason = "Closure end should have the same indentation as the line that started it. " +
                     "Expected \(violation.indentationRanges.expected.length), " +
                     "got \(violation.indentationRanges.actual.length)."

        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severity,
                              location: Location(file: file, byteOffset: violation.endOffset),
                              reason: reason)
    }
}

extension ClosureEndIndentationRule: CorrectableRule {
    func correct(file: SwiftLintFile) -> [Correction] {
        let allViolations = violations(in: file).reversed().filter { violation in
            guard let nsRange = file.stringView.byteRangeToNSRange(violation.range) else {
                return false
            }

            return file.ruleEnabled(violatingRanges: [nsRange], for: self).isNotEmpty
        }

        guard allViolations.isNotEmpty else {
            return []
        }

        var correctedContents = file.contents
        var correctedLocations: [Int] = []

        let actualLookup = actualViolationLookup(for: allViolations)

        for violation in allViolations {
            let expected = actualLookup(violation).indentationRanges.expected
            let actual = violation.indentationRanges.actual
            if correct(contents: &correctedContents, expected: expected, actual: actual) {
                correctedLocations.append(actual.location)
            }
        }

        var corrections = correctedLocations.map {
            return Correction(ruleDescription: Self.description,
                              location: Location(file: file, characterOffset: $0))
        }

        file.write(correctedContents)

        // Re-correct to catch cascading indentation from the first round.
        corrections += correct(file: file)

        return corrections
    }

    private func correct(contents: inout String, expected: NSRange, actual: NSRange) -> Bool {
        guard let actualIndices = contents.nsrangeToIndexRange(actual) else {
            return false
        }

        let regex = Self.notWhitespace
        if regex.firstMatch(in: contents, options: [], range: actual) != nil {
            var correction = "\n"
            correction.append(contents.substring(from: expected.location, length: expected.length))
            contents.insert(contentsOf: correction, at: actualIndices.upperBound)
        } else {
            let correction = contents.substring(from: expected.location, length: expected.length)
            contents = contents.replacingCharacters(in: actualIndices, with: correction)
        }

        return true
    }

    private func actualViolationLookup(for violations: [Violation]) -> (Violation) -> Violation {
        let lookup = violations.reduce(into: [NSRange: Violation](), { result, violation in
            result[violation.indentationRanges.actual] = violation
        })

        func actualViolation(for violation: Violation) -> Violation {
            guard let actual = lookup[violation.indentationRanges.expected] else { return violation }
            return actualViolation(for: actual)
        }

        return actualViolation
    }
}

extension ClosureEndIndentationRule {
    fileprivate struct Violation {
        var indentationRanges: (expected: NSRange, actual: NSRange)
        var endOffset: ByteCount
        var range: ByteRange
    }

    fileprivate func violations(in file: SwiftLintFile) -> [Violation] {
        return file.structureDictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            return violations(in: file, of: kind, dictionary: subDict)
        }
    }

    private func violations(in file: SwiftLintFile, of kind: SwiftExpressionKind,
                            dictionary: SourceKittenDictionary) -> [Violation] {
        guard kind == .call else {
            return []
        }

        var violations = validateArguments(in: file, dictionary: dictionary)

        if let callViolation = validateCall(in: file, dictionary: dictionary) {
            violations.append(callViolation)
        }

        return violations
    }

    private func hasTrailingClosure(in file: SwiftLintFile,
                                    dictionary: SourceKittenDictionary) -> Bool {
        guard
            let byteRange = dictionary.byteRange,
            let text = file.stringView.substringWithByteRange(byteRange)
        else {
            return false
        }

        return !text.hasSuffix(")")
    }

    private func validateCall(in file: SwiftLintFile,
                              dictionary: SourceKittenDictionary) -> Violation? {
        let contents = file.stringView
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let bodyLength = dictionary.bodyLength,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            bodyLength > 0,
            case let endOffset = offset + length - 1,
            case let closingBraceByteRange = ByteRange(location: endOffset, length: 1),
            contents.substringWithByteRange(closingBraceByteRange) == "}",
            let startOffset = startOffset(forDictionary: dictionary, file: file),
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: startOffset),
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            case let nameEndPosition = nameOffset + nameLength,
            let (bodyOffsetLine, _) = contents.lineAndCharacter(forByteOffset: nameEndPosition),
            startLine != endLine, bodyOffsetLine != endLine,
            !containsSingleLineClosure(dictionary: dictionary, endPosition: endOffset, file: file)
        else {
            return nil
        }

        let range = file.lines[startLine - 1].range
        let regex = Self.notWhitespace
        let actual = endPosition - 1
        guard let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            case let expected = match.location - range.location,
            expected != actual
        else {
            return nil
        }

        var expectedRange = range
        expectedRange.length = expected

        var actualRange = file.lines[endLine - 1].range
        actualRange.length = actual

        return Violation(indentationRanges: (expected: expectedRange, actual: actualRange),
                         endOffset: endOffset,
                         range: ByteRange(location: offset, length: length))
    }

    private func validateArguments(in file: SwiftLintFile,
                                   dictionary: SourceKittenDictionary) -> [Violation] {
        guard isFirstArgumentOnNewline(dictionary, file: file) else {
            return []
        }

        var closureArguments = filterClosureArguments(dictionary.enclosedArguments, file: file)

        if hasTrailingClosure(in: file, dictionary: dictionary), closureArguments.isNotEmpty {
            closureArguments.removeLast()
        }

        let argumentViolations = closureArguments.compactMap { dictionary in
            return validateClosureArgument(in: file, dictionary: dictionary)
        }

        return argumentViolations
    }

    private func validateClosureArgument(in file: SwiftLintFile,
                                         dictionary: SourceKittenDictionary) -> Violation? {
        let contents = file.stringView
        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let bodyLength = dictionary.bodyLength,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            bodyLength > 0,
            case let endOffset = offset + length - 1,
            case let closingBraceByteRange = ByteRange(location: endOffset, length: 1),
            contents.substringWithByteRange(closingBraceByteRange) == "}",
            let startOffset = dictionary.offset,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: startOffset),
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            case let nameEndPosition = nameOffset + nameLength,
            let (bodyOffsetLine, _) = contents.lineAndCharacter(forByteOffset: nameEndPosition),
            startLine != endLine, bodyOffsetLine != endLine,
            !isSingleLineClosure(dictionary: dictionary, endPosition: endOffset, file: file)
        else {
            return nil
        }

        let range = file.lines[startLine - 1].range
        let regex = Self.notWhitespace
        let actual = endPosition - 1
        guard let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            case let expected = match.location - range.location,
            expected != actual
        else {
            return nil
        }

        var expectedRange = range
        expectedRange.length = expected

        var actualRange = file.lines[endLine - 1].range
        actualRange.length = actual

        return Violation(indentationRanges: (expected: expectedRange, actual: actualRange),
                         endOffset: endOffset,
                         range: ByteRange(location: offset, length: length))
    }

    private func startOffset(forDictionary dictionary: SourceKittenDictionary, file: SwiftLintFile) -> ByteCount? {
        guard let nameByteRange = dictionary.nameByteRange else {
            return nil
        }

        let newLineRegex = regex("\n(\\s*\\}?\\.)")
        let contents = file.stringView
        guard let range = contents.byteRangeToNSRange(nameByteRange),
            let match = newLineRegex.matches(in: file.contents, options: [], range: range).last?.range(at: 1),
            let methodByteRange = contents.NSRangeToByteRange(start: match.location, length: match.length)
        else {
            return nameByteRange.location
        }

        return methodByteRange.location
    }

    private func isSingleLineClosure(dictionary: SourceKittenDictionary,
                                     endPosition: ByteCount, file: SwiftLintFile) -> Bool {
        let contents = file.stringView

        guard let start = dictionary.bodyOffset,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: start),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: endPosition) else {
                return false
        }

        return startLine == endLine
    }

    private func containsSingleLineClosure(dictionary: SourceKittenDictionary,
                                           endPosition: ByteCount, file: SwiftLintFile) -> Bool {
        let contents = file.stringView

        guard let closure = trailingClosure(dictionary: dictionary, file: file),
            let start = closure.bodyOffset,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: start),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: endPosition) else {
                return false
        }

        return startLine == endLine
    }

    private func trailingClosure(dictionary: SourceKittenDictionary,
                                 file: SwiftLintFile) -> SourceKittenDictionary? {
        let arguments = dictionary.enclosedArguments
        let closureArguments = filterClosureArguments(arguments, file: file)

        if closureArguments.count == 1,
            closureArguments.last?.offset == arguments.last?.offset {
            return closureArguments.last
        }

        return nil
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

    private func isFirstArgumentOnNewline(_ dictionary: SourceKittenDictionary,
                                          file: SwiftLintFile) -> Bool {
        guard
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let firstArgument = dictionary.enclosedArguments.first,
            let firstArgumentOffset = firstArgument.offset,
            case let offset = nameOffset + nameLength,
            case let length = firstArgumentOffset - offset,
            length > 0,
            case let byteRange = ByteRange(location: offset, length: length),
            let range = file.stringView.byteRangeToNSRange(byteRange),
            let match = regex("\\(\\s*\\n\\s*").firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location
        else {
            return false
        }

        return true
    }
}
