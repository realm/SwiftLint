import Foundation
import SourceKittenFramework
import SwiftSyntax

public struct ColonRule: SubstitutionCorrectableRule, ConfigurationProviderRule, AutomaticTestableRule,
                         SourceKitFreeRule {
    public var configuration = ColonConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "colon",
        name: "Colon Spacing",
        description: """
            Colons should be next to the identifier when specifying a type and next to the key in dictionary literals.
            """,
        kind: .style,
        nonTriggeringExamples: ColonRuleExamples.nonTriggeringExamples,
        triggeringExamples: ColonRuleExamples.triggeringExamples,
        corrections: ColonRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        violationRanges(in: file).map { range in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, characterOffset: range.location))
        }
    }

    public func violationRanges(in file: SwiftLintFile) -> [NSRange] {
        guard let syntaxTree = file.syntaxTree else {
            return []
        }

        // Skip colons used for ternary expressions and function references
        let visitor = ColonRuleVisitor()
        visitor.walk(syntaxTree)
        let positionsToSkip = visitor.positionsToSkip
        let dictionaryPositions = visitor.dictionaryPositions

        return Array(syntaxTree.tokens)
            .windows(ofCount: 3)
            .compactMap { tokens -> ByteRange? in
                let previous = tokens[tokens.startIndex]
                let current = tokens[tokens.startIndex + 1]
                let next = tokens[tokens.startIndex + 2]

                if current.tokenKind != .colon ||
                    !configuration.applyToDictionaries && dictionaryPositions.contains(current.position) ||
                    positionsToSkip.contains(current.position) {
                    return nil
                }

                // [:]
                if previous.tokenKind == .leftSquareBracket,
                   next.tokenKind == .rightSquareBracket,
                   previous.trailingTrivia.isEmpty,
                   current.leadingTrivia.isEmpty,
                   current.trailingTrivia.isEmpty,
                   next.leadingTrivia.isEmpty {
                    return nil
                }

                if previous.trailingTrivia.isNotEmpty && !current.leadingTrivia.containsBlockComments() {
                    let start = ByteCount(previous.endPositionBeforeTrailingTrivia)
                    let end = ByteCount(current.endPosition)
                    return ByteRange(location: start, length: end - start)
                } else if current.trailingTrivia != [.spaces(1)] && !next.leadingTrivia.containsNewlines() {
                    if configuration.flexibleRightSpacing && current.trailingTrivia.isNotEmpty {
                        return nil
                    }

                    let length: ByteCount
                    if case let .spaces(spaces) = current.trailingTrivia.first {
                        length = ByteCount(spaces + 1)
                    } else {
                        length = 1
                    }

                    return ByteRange(location: ByteCount(current.position), length: length)
                } else {
                    return nil
                }
            }
            .compactMap { byteRange in
                file.stringView.byteRangeToNSRange(byteRange)
            }
    }

    public func substitution(for violationRange: NSRange, in file: SwiftLintFile) -> (NSRange, String)? {
        (violationRange, ": ")
    }
}

private final class ColonRuleVisitor: SyntaxVisitor {
    var positionsToSkip: [AbsolutePosition] = []
    var dictionaryPositions: [AbsolutePosition] = []

    override func visitPost(_ node: TernaryExprSyntax) {
        positionsToSkip.append(node.colonMark.position)
    }

    override func visitPost(_ node: DeclNameArgumentsSyntax) {
        positionsToSkip.append(
            contentsOf: node.tokens
                .filter { $0.tokenKind == .colon }
                .map(\.position)
        )
    }

    override func visitPost(_ node: ObjCSelectorPieceSyntax) {
        if let colon = node.colon {
            positionsToSkip.append(colon.position)
        }
    }

    override func visitPost(_ node: DictionaryElementSyntax) {
        dictionaryPositions.append(node.colon.position)
    }
}

private extension Trivia {
    func containsBlockComments() -> Bool {
        contains { piece in
            if case .blockComment = piece {
                return true
            } else {
                return false
            }
        }
    }

    func containsNewlines() -> Bool {
        contains { piece in
            if case .newlines = piece {
                return true
            } else {
                return false
            }
        }
    }
}
