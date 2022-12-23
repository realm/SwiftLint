import Foundation
import SourceKittenFramework

struct LiteralExpressionEndIdentationRule: Rule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "literal_expression_end_indentation",
        name: "Literal Expression End Indentation",
        description: "Array and dictionary literal end should have the same indentation as the line that started it",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            [1, 2, 3]
            """),
            Example("""
            [1,
             2
            ]
            """),
            Example("""
            [
               1,
               2
            ]
            """),
            Example("""
            [
               1,
               2]
            """),
            Example("""
               let x = [
                   1,
                   2
               ]
            """),
            Example("""
            [key: 2, key2: 3]
            """),
            Example("""
            [key: 1,
             key2: 2
            ]
            """),
            Example("""
            [
               key: 0,
               key2: 20
            ]
            """)
        ],
        triggeringExamples: [
            Example("""
            let x = [
               1,
               2
               ↓]
            """),
            Example("""
               let x = [
                   1,
                   2
            ↓]
            """),
            Example("""
            let x = [
               key: value
               ↓]
            """)
        ],
        corrections: [
            Example("""
            let x = [
               key: value
            ↓   ]
            """): Example("""
            let x = [
               key: value
            ]
            """),
            Example("""
               let x = [
                   1,
                   2
            ↓]
            """): Example("""
               let x = [
                   1,
                   2
               ]
            """),
            Example("""
            let x = [
               1,
               2
            ↓   ]
            """): Example("""
            let x = [
               1,
               2
            ]
            """),
            Example("""
            let x = [
               1,
               2
            ↓   ] + [
               3,
               4
            ↓   ]
            """): Example("""
            let x = [
               1,
               2
            ] + [
               3,
               4
            ]
            """)
        ]
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violations(in: file).map { violation in
            return styleViolation(for: violation, in: file)
        }
    }

    private func styleViolation(for violation: Violation, in file: SwiftLintFile) -> StyleViolation {
        let reason = "\(Self.description.description); " +
                     "expected indentation of \(violation.indentationRanges.expected.length), " +
                     "got \(violation.indentationRanges.actual.length)"

        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severity,
                              location: Location(file: file, byteOffset: violation.endOffset),
                              reason: reason)
    }

    fileprivate static let notWhitespace = regex("[^\\s]")
}

extension LiteralExpressionEndIdentationRule: CorrectableRule {
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

        let correction = contents.substring(from: expected.location, length: expected.length)
        contents = contents.replacingCharacters(in: actualIndices, with: correction)

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

extension LiteralExpressionEndIdentationRule {
    fileprivate struct Violation {
        var indentationRanges: (expected: NSRange, actual: NSRange)
        var endOffset: ByteCount
        var range: ByteRange
    }

    fileprivate func violations(in file: SwiftLintFile) -> [Violation] {
        return file.structureDictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.expressionKind else { return nil }
            guard let violation = violation(in: file, of: kind, dictionary: subDict) else { return nil }
            return [violation]
        }
    }

    private func violation(in file: SwiftLintFile, of kind: SwiftExpressionKind,
                           dictionary: SourceKittenDictionary) -> Violation? {
        guard kind == .dictionary || kind == .array else {
            return nil
        }

        let elements = dictionary.elements.filter { $0.kind == "source.lang.swift.structure.elem.expr" }

        let contents = file.stringView
        guard elements.isNotEmpty,
            let offset = dictionary.offset,
            let length = dictionary.length,
            let (startLine, _) = contents.lineAndCharacter(forByteOffset: offset),
            let firstParamOffset = elements[0].offset,
            let (firstParamLine, _) = contents.lineAndCharacter(forByteOffset: firstParamOffset),
            startLine != firstParamLine,
            let lastParamOffset = elements.last?.offset,
            let (lastParamLine, _) = contents.lineAndCharacter(forByteOffset: lastParamOffset),
            case let endOffset = offset + length - 1,
            let (endLine, endPosition) = contents.lineAndCharacter(forByteOffset: endOffset),
            lastParamLine != endLine
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
}
