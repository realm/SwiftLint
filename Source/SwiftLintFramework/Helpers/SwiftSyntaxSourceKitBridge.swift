import SourceKittenFramework
import SwiftSyntax

// This file contains a pile of hacks in order to convert the syntax classifications provided by SwiftSyntax to the
// data that SourceKit used to provide.

/// Holds code to bridge SwiftSyntax concepts to SourceKit concepts.
enum SwiftSyntaxSourceKitBridge {
    static func tokens(file: SwiftLintFile) -> [SwiftLintSyntaxToken] {
        file.allTokens()
    }
}

// MARK: - Private

private extension SwiftLintFile {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func allTokens() -> [SwiftLintSyntaxToken] {
        let visitor = QuoteVisitor(viewMode: .sourceAccurate)
        let syntaxTree = self.syntaxTree
        visitor.walk(syntaxTree)
        let openQuoteRanges = visitor.openQuoteRanges.sorted(by: { $0.offset < $1.offset })
        let closeQuoteRanges = visitor.closeQuoteRanges.sorted(by: { $0.offset < $1.offset })
        let classifications = Array(syntaxTree.classifications)
        let new1 = classifications.enumerated().compactMap { index, classification -> SwiftLintSyntaxToken? in
            guard var syntaxKind = classification.kind.toSyntaxKind() else {
                return nil
            }

            var offset = ByteCount(classification.offset)
            var length = ByteCount(classification.length)

            let lastCharRange = ByteRange(location: offset + length, length: 1)
            if syntaxKind.isCommentLike,
               classification.kind != .docBlockComment,
               classification.kind != .blockComment,
               index != classifications.count - 1, // Don't adjust length if this is the last classification
               stringView.substringWithByteRange(lastCharRange)?.allSatisfy(\.isNewline) == true {
                length += 1
            } else if syntaxKind == .string {
                if let openQuote = openQuoteRanges.first(where: { $0.intersectsOrTouches(classification.range) }) {
                    let diff = offset - ByteCount(openQuote.offset)
                    offset = ByteCount(openQuote.offset)
                    length += diff
                }

                if let closeQuote = closeQuoteRanges.first(where: { $0.intersectsOrTouches(classification.range) }) {
                    length = ByteCount(closeQuote.endOffset) - offset
                }
            }

            if syntaxKind == .keyword,
               case let byteRange = ByteRange(location: offset, length: length),
               let substring = stringView.substringWithByteRange(byteRange) {
                if substring == "Self" {
                    // SwiftSyntax considers 'Self' a keyword, but SourceKit considers it a type identifier.
                    syntaxKind = .typeidentifier
                } else if ["unavailable", "swift", "deprecated", "introduced"].contains(substring) {
                    // SwiftSyntax considers 'unavailable' & 'swift' a keyword, but SourceKit considers it an
                    // identifier.
                    syntaxKind = .identifier
                } else if substring == "throws" {
                    // SwiftSyntax considers `throws` a keyword, but SourceKit ignores it.
                    return nil
                } else if AccessControlLevel(description: substring) != nil || substring == "final" ||
                            substring == "lazy" || substring == "convenience" {
                    // SwiftSyntax considers ACL keywords as keywords, but SourceKit considers them to be built-in
                    // attributes.
                    syntaxKind = .attributeBuiltin
                } else if substring == "for" && stringView.substringWithByteRange(lastCharRange) == ":" {
                    syntaxKind = .identifier
                }
            }

            if classification.kind == .poundDirectiveKeyword,
               case let byteRange = ByteRange(location: offset, length: length),
               let substring = stringView.substringWithByteRange(byteRange),
               substring == "#warning" || substring == "#error" {
                syntaxKind = .poundDirectiveKeyword
            }

            let syntaxToken = SyntaxToken(type: syntaxKind.rawValue, offset: offset, length: length)
            return SwiftLintSyntaxToken(value: syntaxToken)
        }

        // Combine `@` with next keyword
        var new: [SwiftLintSyntaxToken] = []
        var eatNext = false
        for (index, asdf) in new1.enumerated() {
            if eatNext {
                let previous = new.removeLast()
                let newToken = SwiftLintSyntaxToken(
                    value: SyntaxToken(
                        type: previous.value.type,
                        offset: previous.offset,
                        length: previous.length + asdf.length
                    )
                )
                new.append(newToken)
                eatNext = false
            } else if asdf.kind == .attributeBuiltin && asdf.length == 1 && new1[index + 1].kind == .keyword {
                eatNext = true
                new.append(asdf)
            } else if asdf.kind == .attributeBuiltin && asdf.length == 1 && new1[index + 1].kind == .typeidentifier {
                continue
            } else {
                new.append(asdf)
            }
        }

        return new
    }
}

private extension SyntaxClassification {
    // swiftlint:disable:next cyclomatic_complexity
    func toSyntaxKind() -> SyntaxKind? {
        switch self {
        case .none:
            return nil
        case .keyword:
            return .keyword
        case .identifier:
            return .identifier
        case .typeIdentifier:
            return .typeidentifier
        case .dollarIdentifier:
            return .identifier
        case .integerLiteral:
            return .number
        case .floatingLiteral:
            return .number
        case .stringLiteral:
            return .string
        case .stringInterpolationAnchor:
            return .stringInterpolationAnchor
        case .buildConfigId:
            return .buildconfigID
        case .poundDirectiveKeyword:
            return .buildconfigKeyword
        case .attribute:
            return .attributeBuiltin
        case .objectLiteral:
            return .objectLiteral
        case .editorPlaceholder:
            return .placeholder
        case .lineComment:
            return .comment
        case .docLineComment:
            return .docComment
        case .blockComment:
            return .comment
        case .docBlockComment:
            return .docComment
        case .operatorIdentifier:
            return nil
        }
    }
}

private final class QuoteVisitor: SyntaxVisitor {
    var openQuoteRanges: [ByteSourceRange] = []
    var closeQuoteRanges: [ByteSourceRange] = []

    override func visitPost(_ node: StringLiteralExprSyntax) {
        if let openDelimiter = node.openDelimiter {
            let offset = openDelimiter.positionAfterSkippingLeadingTrivia.utf8Offset
            let end = node.openQuote.endPosition.utf8Offset
            openQuoteRanges.append(ByteSourceRange(offset: offset, length: end - offset))
        } else {
            let offset = node.openQuote.positionAfterSkippingLeadingTrivia.utf8Offset
            let range = ByteSourceRange(
                offset: offset,
                length: node.openQuote.endPositionBeforeTrailingTrivia.utf8Offset - offset
            )
            openQuoteRanges.append(range)
        }

        if let closeDelimiter = node.closeDelimiter {
            let offset = node.closeQuote.position.utf8Offset
            let end = closeDelimiter.endPositionBeforeTrailingTrivia.utf8Offset
            closeQuoteRanges.append(ByteSourceRange(offset: offset, length: end - offset))
        } else {
            let offset = node.closeQuote.position.utf8Offset
            let range = ByteSourceRange(
                offset: offset,
                length: node.closeQuote.endPositionBeforeTrailingTrivia.utf8Offset - offset
            )
            closeQuoteRanges.append(range)
        }
    }
}
