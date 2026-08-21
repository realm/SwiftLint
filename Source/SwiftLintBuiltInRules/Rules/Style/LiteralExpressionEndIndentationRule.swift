import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

struct LiteralExpressionEndIndentationRule: Rule, OptInRule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "literal_expression_end_indentation",
        name: "Literal Expression End Indentation",
        description: "Array and dictionary literal end should have the same indentation as the line that started it",
        kind: .style,
        nonTriggeringExamples: #examples([
            """
            [1, 2, 3]
            """,
            """
            [1,
             2
            ]
            """,
            """
            [
               1,
               2
            ]
            """,
            """
            [
               1,
               2]
            """,
            """
               let x = [
                   1,
                   2
               ]
            """,
            """
            [key: 2, key2: 3]
            """,
            """
            [key: 1,
             key2: 2
            ]
            """,
            """
            [
               key: 0,
               key2: 20
            ]
            """,
        ]),
        triggeringExamples: #examples([
            """
            let x = [
               1,
               2
               ↓]
            """,
            """
               let x = [
                   1,
                   2
            ↓]
            """,
            """
            let x = [
               key: value
               ↓]
            """,
            """
            let x = [
               foo(
                  1,
                  2)↓]
            """,
        ]),
        corrections: #corrections([
            """
            let x = [
               key: value
            ↓   ]
            """: """
            let x = [
               key: value
            ]
            """,
            """
               let x = [
                   1,
                   2
            ↓]
            """: """
               let x = [
                   1,
                   2
               ]
            """,
            """
            let x = [
               1,
               2
            ↓   ]
            """: """
            let x = [
               1,
               2
            ]
            """,
            """
            let x = [
               1,
               2
            ↓   ] + [
               3,
               4
            ↓   ]
            """: """
            let x = [
               1,
               2
            ] + [
               3,
               4
            ]
            """,
            """
            let x = [
               foo(
                  1,
                  2)↓]
            """: """
            let x = [
               foo(
                  1,
                  2)
            ]
            """,
        ])
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        violations(in: file).map { violation in
            styleViolation(for: violation, in: file)
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

extension LiteralExpressionEndIndentationRule: CorrectableRule {
    func correct(file: SwiftLintFile) -> Int {
        let allViolations = violations(in: file).reversed().filter { violation in
            guard let nsRange = file.stringView.byteRangeToNSRange(violation.range) else {
                return false
            }
            return file.ruleEnabled(violatingRanges: [nsRange], for: self).isNotEmpty
        }
        guard allViolations.isNotEmpty else {
            return 0
        }
        var correctedContents = file.contents
        let actualLookup = actualViolationLookup(for: allViolations)
        var numberOfCorrections = 0
        for violation in allViolations {
            let expected = actualLookup(violation).indentationRanges.expected
            let actual = violation.indentationRanges.actual
            if correct(contents: &correctedContents, expected: expected, actual: actual) {
                numberOfCorrections += 1
            }
        }
        file.write(correctedContents)

        // Re-correct to catch cascading indentation from the first round.
        numberOfCorrections += correct(file: file)
        return numberOfCorrections
    }

    private func correct(contents: inout String, expected: NSRange, actual: NSRange) -> Bool {
        guard let actualIndices = contents.nsrangeToIndexRange(actual) else {
            return false
        }

        let correction = contents.substring(from: expected.location, length: expected.length)
        if contents[actualIndices].allSatisfy(\.isWhitespace) {
            contents = contents.replacingCharacters(in: actualIndices, with: correction)
        } else {
            contents.insert(contentsOf: "\n" + correction, at: actualIndices.upperBound)
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

extension LiteralExpressionEndIndentationRule {
    fileprivate struct Violation {
        var indentationRanges: (expected: NSRange, actual: NSRange)
        var endOffset: ByteCount
        var range: ByteRange
    }

    fileprivate struct Literal {
        var offset: ByteCount
        var length: ByteCount
        var firstElementOffset: ByteCount
        var lastElementOffset: ByteCount
    }

    fileprivate func violations(in file: SwiftLintFile) -> [Violation] {
        LiteralExpressionVisitor(viewMode: .sourceAccurate)
            .walk(file: file) { $0.literals }
            .compactMap { literal in
                violation(in: file, literal: literal)
            }
    }

    private func violation(in file: SwiftLintFile, literal: Literal) -> Violation? {
        let contents = file.stringView
        let offset = literal.offset
        guard let (startLine, _) = contents.lineAndCharacter(forByteOffset: offset),
              let (firstParamLine, _) = contents.lineAndCharacter(forByteOffset: literal.firstElementOffset),
              startLine != firstParamLine,
              let (lastParamLine, _) = contents.lineAndCharacter(forByteOffset: literal.lastElementOffset),
              case let endOffset = offset + literal.length - 1,
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
                         range: ByteRange(location: offset, length: literal.length))
    }
}

private final class LiteralExpressionVisitor: SyntaxVisitor {
    private(set) var literals: [LiteralExpressionEndIndentationRule.Literal] = []

    override func visitPost(_ node: ArrayExprSyntax) {
        appendLiteral(leftSquare: node.leftSquare,
                      rightSquare: node.rightSquare,
                      firstElement: node.elements.first?.expression,
                      lastElement: node.elements.last?.expression)
    }

    override func visitPost(_ node: DictionaryExprSyntax) {
        guard case let .elements(elements) = node.content else {
            return
        }
        appendLiteral(leftSquare: node.leftSquare,
                      rightSquare: node.rightSquare,
                      firstElement: elements.first?.key,
                      lastElement: elements.last?.value)
    }

    private func appendLiteral(leftSquare: TokenSyntax,
                               rightSquare: TokenSyntax,
                               firstElement: ExprSyntax?,
                               lastElement: ExprSyntax?) {
        guard let firstElement, let lastElement else {
            return
        }

        let offset = ByteCount(leftSquare.positionAfterSkippingLeadingTrivia)
        let endOffset = ByteCount(rightSquare.positionAfterSkippingLeadingTrivia)
        literals.append(.init(offset: offset,
                              length: endOffset - offset + 1,
                              firstElementOffset: ByteCount(firstElement.positionAfterSkippingLeadingTrivia),
                              lastElementOffset: ByteCount(lastElement.positionAfterSkippingLeadingTrivia)))
    }
}
