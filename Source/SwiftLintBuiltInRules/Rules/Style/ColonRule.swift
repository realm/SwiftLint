import Foundation
import SourceKittenFramework
@_spi(RawSyntax)
import SwiftSyntax

struct ColonRule: SubstitutionCorrectableRule, SourceKitFreeRule {
    var configuration = ColonConfiguration()

    static let description = RuleDescription(
        identifier: "colon",
        name: "Colon Spacing",
        description: """
            Colons should be next to the identifier when specifying a type and next to the key in dictionary literals
            """,
        kind: .style,
        nonTriggeringExamples: ColonRuleExamples.nonTriggeringExamples,
        triggeringExamples: ColonRuleExamples.triggeringExamples,
        corrections: ColonRuleExamples.corrections
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        violationRanges(in: file).map { range in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: range.location))
        }
    }

    func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        let syntaxTree = file.syntaxTree
        let visitor = ColonRuleVisitor(viewMode: .sourceAccurate)
        visitor.walk(syntaxTree)
        let positionsToSkip = visitor.positionsToSkip
        let dictionaryPositions = visitor.dictionaryPositions
        let caseStatementPositions = visitor.caseStatementPositions
        let applyToDictionaries = configuration.applyToDictionaries
        let flexibleRightSpacingConfigured = configuration.flexibleRightSpacing
        let stringView = file.stringView

        // Single pass over all windows of three consecutive tokens where the middle token is a
        // colon. Checking `rawTokenKind` avoids materializing a `TokenKind` (and its text) for
        // every token in the file.
        var violations = [NSRange]()
        var previousToken: TokenSyntax?
        var currentToken: TokenSyntax?
        for next in syntaxTree.tokens(viewMode: .sourceAccurate) {
            defer {
                previousToken = currentToken
                currentToken = next
            }
            guard let current = currentToken, current.rawTokenKind == .colon,
                  let previous = previousToken else {
                continue
            }
            let position = current.position
            if !applyToDictionaries && dictionaryPositions.contains(position) ||
                positionsToSkip.contains(position) {
                continue
            }

            let byteRange = Self.violationByteRange(
                previous: previous,
                current: current,
                next: next,
                flexibleRightSpacingConfigured: flexibleRightSpacingConfigured,
                caseStatementPositions: caseStatementPositions
            )
            if let byteRange, let range = stringView.byteRangeToNSRange(byteRange) {
                violations.append(range)
            }
        }
        return violations
    }

    /// The byte range of the spacing violation around the colon token `current`, if any.
    private static func violationByteRange(previous: TokenSyntax,
                                           current: TokenSyntax,
                                           next: TokenSyntax,
                                           flexibleRightSpacingConfigured: Bool,
                                           caseStatementPositions: [AbsolutePosition]) -> ByteRange? {
        let previousTrailingTrivia = previous.trailingTrivia
        let currentTrailingTrivia = current.trailingTrivia

        // [:]
        if previous.rawTokenKind == .leftSquare,
           next.rawTokenKind == .rightSquare,
           previousTrailingTrivia.isEmpty,
           current.leadingTrivia.isEmpty,
           currentTrailingTrivia.isEmpty,
           next.leadingTrivia.isEmpty {
            return nil
        }

        if previousTrailingTrivia.isNotEmpty, !previousTrailingTrivia.containsBlockComments() {
            let start = ByteCount(previous.endPositionBeforeTrailingTrivia)
            let end = ByteCount(current.endPosition)
            return ByteRange(location: start, length: end - start)
        }
        if currentTrailingTrivia != [.spaces(1)], !next.leadingTrivia.containsNewlines() {
            if case .spaces(1) = currentTrailingTrivia.first {
                return nil
            }

            let position = current.position
            let flexibleRightSpacing = flexibleRightSpacingConfigured ||
                caseStatementPositions.contains(position)
            if flexibleRightSpacing, currentTrailingTrivia.isNotEmpty {
                return nil
            }

            let length: ByteCount
            if case let .spaces(spaces) = currentTrailingTrivia.first {
                length = ByteCount(spaces + 1)
            } else {
                length = 1
            }

            return ByteRange(location: ByteCount(position), length: length)
        }
        return nil
    }

    func substitution(for violationRange: NSRange, in _: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, ": ")
    }
}

private final class ColonRuleVisitor: SyntaxVisitor {
    var positionsToSkip: [AbsolutePosition] = []
    var dictionaryPositions: [AbsolutePosition] = []
    var caseStatementPositions: [AbsolutePosition] = []

    override func visitPost(_ node: TernaryExprSyntax) {
        positionsToSkip.append(node.colon.position)
    }

    override func visitPost(_ node: DeclNameArgumentsSyntax) {
        positionsToSkip.append(
            contentsOf: node.tokens(viewMode: .sourceAccurate)
                .filter { $0.rawTokenKind == .colon }
                .map(\.position)
        )
    }

    override func visitPost(_ node: ObjCSelectorPieceSyntax) {
        if let colon = node.colon {
            positionsToSkip.append(colon.position)
        }
    }

    override func visitPost(_ node: OperatorPrecedenceAndTypesSyntax) {
        positionsToSkip.append(node.colon.position)
    }

    override func visitPost(_ node: UnresolvedTernaryExprSyntax) {
        positionsToSkip.append(node.colon.position)
    }

    override func visitPost(_ node: DictionaryElementSyntax) {
        dictionaryPositions.append(node.colon.position)
    }

    override func visitPost(_ node: SwitchCaseLabelSyntax) {
        caseStatementPositions.append(node.colon.position)
    }

    override func visitPost(_ node: SwitchDefaultLabelSyntax) {
        caseStatementPositions.append(node.colon.position)
    }
}

private extension Trivia {
    func containsBlockComments() -> Bool {
        contains { piece in
            if case .blockComment = piece {
                return true
            }
            return false
        }
    }
}
