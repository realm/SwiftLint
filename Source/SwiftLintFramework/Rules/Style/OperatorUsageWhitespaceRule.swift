import Foundation
import SourceKittenFramework
import SwiftSyntax

struct OperatorUsageWhitespaceRule: OptInRule, CorrectableRule, ConfigurationProviderRule, SourceKitFreeRule {
    var configuration = OperatorUsageWhitespaceConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "operator_usage_whitespace",
        name: "Operator Usage Whitespace",
        description: "Operators should be surrounded by a single whitespace when they are being used",
        kind: .style,
        nonTriggeringExamples: OperatorUsageWhitespaceRuleExamples.nonTriggeringExamples,
        triggeringExamples: OperatorUsageWhitespaceRuleExamples.triggeringExamples,
        corrections: OperatorUsageWhitespaceRuleExamples.corrections
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return violationRanges(file: file).map { range, _ in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: range.location))
        }
    }

    private func violationRanges(file: SwiftLintFile) -> [(ByteRange, String)] {
        OperatorUsageWhitespaceVisitor(
            allowedNoSpaceOperators: configuration.allowedNoSpaceOperators
        )
        .walk(file: file, handler: \.violationRanges)
        .filter { byteRange, _ in
            !configuration.skipAlignedConstants || !isAlignedConstant(in: byteRange, file: file)
        }.sorted { lhs, rhs in
            lhs.0.location < rhs.0.location
        }
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let violatingRanges = violationRanges(file: file)
            .compactMap { byteRange, correction -> (NSRange, String)? in
                guard let range = file.stringView.byteRangeToNSRange(byteRange) else {
                    return nil
                }

                return (range, correction)
            }
            .filter { range, _ in
                return file.ruleEnabled(violatingRanges: [range], for: self).isNotEmpty
            }

        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for (violatingRange, correction) in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: correction)
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: Self.description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func isAlignedConstant(in byteRange: ByteRange, file: SwiftLintFile) -> Bool {
        // Make sure we have match with assignment operator and with spaces before it
        guard let matchedString = file.stringView.substringWithByteRange(byteRange) else {
            return false
        }
        let equalityOperatorRegex = regex("\\s+=\\s")

        guard let match = equalityOperatorRegex.firstMatch(
            in: matchedString,
            options: [],
            range: matchedString.fullNSRange),
              match.range == matchedString.fullNSRange
        else {
            return false
        }

        guard let (lineNumber, _) = file.stringView.lineAndCharacter(forByteOffset: byteRange.upperBound),
              case let lineIndex = lineNumber - 1, lineIndex >= 0 else {
            return false
        }

        // Find lines above and below with the same location of =
        let currentLine = file.stringView.lines[lineIndex].content
        let index = currentLine.firstIndex(of: "=")
        guard let offset = index.map({ currentLine.distance(from: currentLine.startIndex, to: $0) }) else {
            return false
        }

        // Look around for assignment operator in lines around
        let lineIndexesAround = (1...configuration.linesLookAround)
            .flatMap { [lineIndex + $0, lineIndex - $0] }

        func isValidIndex(_ idx: Int) -> Bool {
            return idx != lineIndex && idx >= 0 && idx < file.stringView.lines.count
        }

        for lineIndex in lineIndexesAround where isValidIndex(lineIndex) {
            let line = file.stringView.lines[lineIndex].content
            guard !line.isEmpty else { continue }
            let index = line.index(line.startIndex,
                                   offsetBy: offset,
                                   limitedBy: line.index(line.endIndex, offsetBy: -1))
            if index.map({ line[$0] }) == "=" {
                return true
            }
        }

        return false
    }
}

private class OperatorUsageWhitespaceVisitor: SyntaxVisitor {
    private let allowedNoSpaceOperators: Set<String>
    private(set) var violationRanges: [(ByteRange, String)] = []

    init(allowedNoSpaceOperators: [String]) {
        self.allowedNoSpaceOperators = Set(allowedNoSpaceOperators)
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: BinaryOperatorExprSyntax) {
        if let violation = violation(operatorToken: node.operatorToken) {
            violationRanges.append(violation)
        }
    }

    override func visitPost(_ node: InitializerClauseSyntax) {
        if let violation = violation(operatorToken: node.equal) {
            violationRanges.append(violation)
        }
    }

    override func visitPost(_ node: TypeInitializerClauseSyntax) {
        if let violation = violation(operatorToken: node.equal) {
            violationRanges.append(violation)
        }
    }

    override func visitPost(_ node: AssignmentExprSyntax) {
        if let violation = violation(operatorToken: node.assignToken) {
            violationRanges.append(violation)
        }
    }

    override func visitPost(_ node: TernaryExprSyntax) {
        if let violation = violation(operatorToken: node.colonMark) {
            violationRanges.append(violation)
        }

        if let violation = violation(operatorToken: node.questionMark) {
            violationRanges.append(violation)
        }
    }

    override func visitPost(_ node: UnresolvedTernaryExprSyntax) {
        if let violation = violation(operatorToken: node.colonMark) {
            violationRanges.append(violation)
        }

        if let violation = violation(operatorToken: node.questionMark) {
            violationRanges.append(violation)
        }
    }

    private func violation(operatorToken: TokenSyntax) -> (ByteRange, String)? {
        guard let previousToken = operatorToken.previousToken,
              let nextToken = operatorToken.nextToken else {
            return nil
        }

        let noSpacingBefore = previousToken.trailingTrivia.isEmpty && operatorToken.leadingTrivia.isEmpty
        let noSpacingAfter = operatorToken.trailingTrivia.isEmpty && nextToken.leadingTrivia.isEmpty
        let noSpacing = noSpacingBefore || noSpacingAfter

        let operatorText = operatorToken.text
        if noSpacing && allowedNoSpaceOperators.contains(operatorText) {
            return nil
        }

        let tooMuchSpacingBefore = previousToken.trailingTrivia.containsTooMuchWhitespacing &&
            !operatorToken.leadingTrivia.containsNewlines()
        let tooMuchSpacingAfter = operatorToken.trailingTrivia.containsTooMuchWhitespacing &&
            !operatorToken.trailingTrivia.containsNewlines()

        let tooMuchSpacing = (tooMuchSpacingBefore || tooMuchSpacingAfter) &&
            !operatorToken.leadingTrivia.containsComments &&
            !operatorToken.trailingTrivia.containsComments &&
            !nextToken.leadingTrivia.containsComments

        guard noSpacing || tooMuchSpacing else {
            return nil
        }

        let location = ByteCount(previousToken.endPositionBeforeTrailingTrivia)
        let endPosition = ByteCount(nextToken.positionAfterSkippingLeadingTrivia)
        let range = ByteRange(
            location: location,
            length: endPosition - location
        )

        let correction = allowedNoSpaceOperators.contains(operatorText) ? operatorText : " \(operatorText) "
        return (range, correction)
    }
}

private extension Trivia {
    var containsTooMuchWhitespacing: Bool {
        return contains { element in
            guard case let .spaces(spaces) = element, spaces > 1 else {
                return false
            }

            return true
        }
    }

    var containsComments: Bool {
        return contains { element in
            switch element {
            case .blockComment, .docLineComment, .docBlockComment, .lineComment:
                return true
            case .backslashes, .carriageReturnLineFeeds, .carriageReturns, .formfeeds, .newlines, .pounds,
                 .shebang, .spaces, .tabs, .unexpectedText, .verticalTabs:
                return false
            }
        }
    }
}
