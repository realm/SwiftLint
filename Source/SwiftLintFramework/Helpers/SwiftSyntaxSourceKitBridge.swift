import SourceKittenFramework
import SwiftSyntax

// This file contains a pile of hacks in order to convert the syntax classifications provided by SwiftSyntax to the
// data that SourceKit used to provide.

/// Holds code to bridge SwiftSyntax concepts to SourceKit concepts.
enum SwiftSyntaxSourceKitBridge {
    static func tokens(file: SwiftLintFile, in byteRange: ByteRange) -> [SwiftLintSyntaxToken] {
        file.tokens(in: byteRange)
    }

    static func allTokens(file: SwiftLintFile) -> [SwiftLintSyntaxToken] {
        file.allTokens()
    }
}

// MARK: - Private

private extension SwiftLintFile {
    func allTokens() -> [SwiftLintSyntaxToken] {
        let visitor = QuoteVisitor(viewMode: .sourceAccurate)
        let syntaxTree = self.syntaxTree
        visitor.walk(syntaxTree)
        let openQuoteRanges = visitor.openQuoteRanges.sorted(by: { $0.offset < $1.offset })
        let closeQuoteRanges = visitor.closeQuoteRanges.sorted(by: { $0.offset < $1.offset })
        let classifications = syntaxTree.classifications
        let new = classifications.compactMap { classification -> SwiftLintSyntaxToken? in
            guard var syntaxKind = classification.kind.toSyntaxKind() else {
                return nil
            }

            var offset = ByteCount(classification.offset)
            var length = ByteCount(classification.length)

            let lastCharRange = ByteRange(location: offset + length, length: 1)
            if syntaxKind.isCommentLike,
               classification.kind != .docBlockComment,
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
                } else if substring == "throws" {
                    // SwiftSyntax considers `throws` a keyword, but SourceKit ignores it.
                    return nil
                } else if AccessControlLevel(description: substring) != nil {
                    // SwiftSyntax considers ACL keywords as keywords, but SourceKit considers them to be built-in
                    // attributes.
                    syntaxKind = .attributeBuiltin
                }
            }

            let syntaxToken = SyntaxToken(type: syntaxKind.rawValue, offset: offset, length: length)
            return SwiftLintSyntaxToken(value: syntaxToken)
        }
        // Uncomment to debug mismatches from what SourceKit provides and what we get via SwiftSyntax
        let old = syntaxMap.tokens
        if new != old {
            queuedPrint("File: \(self.path!)")
            queuedPrint("Old")
            queuedPrint(old)
            queuedPrint("New")
            queuedPrint(new)
            queuedPrint("Classifications")
            var desc = ""
            dump(classifications, to: &desc)
            queuedFatalError(desc)
        }
        return new
    }

    func tokens(in byteRange: ByteRange) -> [SwiftLintSyntaxToken] {
        let visitor = QuoteVisitor(viewMode: .sourceAccurate)
        let syntaxTree = self.syntaxTree
        visitor.walk(syntaxTree)
        let openQuoteRanges = visitor.openQuoteRanges.sorted(by: { $0.offset < $1.offset })
        let closeQuoteRanges = visitor.closeQuoteRanges.sorted(by: { $0.offset < $1.offset })
        let byteSourceRange = ByteSourceRange(offset: byteRange.location.value, length: byteRange.length.value)
        let classifications = syntaxTree.classifications(in: byteSourceRange)
        let new = classifications.compactMap { classification -> SwiftLintSyntaxToken? in
            guard var syntaxKind = classification.kind.toSyntaxKind() else {
                return nil
            }

            var offset = ByteCount(classification.offset)
            var length = ByteCount(classification.length)

            let lastCharRange = ByteRange(location: offset + length, length: 1)
            if syntaxKind.isCommentLike,
               classification.kind != .docBlockComment,
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
                } else if substring == "throws" {
                    // SwiftSyntax considers `throws` a keyword, but SourceKit ignores it.
                    return nil
                } else if AccessControlLevel(description: substring) != nil {
                    // SwiftSyntax considers ACL keywords as keywords, but SourceKit considers them to be built-in
                    // attributes.
                    syntaxKind = .attributeBuiltin
                }
            }

            let syntaxToken = SyntaxToken(type: syntaxKind.rawValue, offset: offset, length: length)
            return SwiftLintSyntaxToken(value: syntaxToken)
        }
        // Uncomment to debug mismatches from what SourceKit provides and what we get via SwiftSyntax
//        let old = syntaxMap.tokens(inByteRange: byteRange)
//        if new != old {
//            queuedPrint("File: \(self.path!)")
//            queuedPrint("Requested byte range: \(byteRange)")
//            queuedPrint("Old")
//            queuedPrint(old)
//            queuedPrint("New")
//            queuedPrint(new)
//            queuedPrint("Classifications")
//            var desc = ""
//            dump(classifications, to: &desc)
//            queuedFatalError(desc)
//        }
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
        case .poundDirectiveKeyword, .buildConfigId:
            return .poundDirectiveKeyword
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
