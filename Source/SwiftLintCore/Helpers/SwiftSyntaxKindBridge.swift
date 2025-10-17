import SourceKittenFramework
import SwiftIDEUtils
import SwiftSyntax

/// Bridge to convert SwiftSyntax classifications to SourceKitten syntax kinds.
/// This enables SwiftSyntax-based custom rules to work with kind filtering
/// without making any SourceKit calls.
public enum SwiftSyntaxKindBridge {
    /// Map a SwiftSyntax classification to SourceKitten syntax kind.
    static func mapClassification(_ classification: SyntaxClassification) -> SourceKittenFramework.SyntaxKind? {
        // swiftlint:disable:previous cyclomatic_complexity
        switch classification {
        case .attribute:
            .attributeID
        case .blockComment, .lineComment:
            .comment
        case .docBlockComment, .docLineComment:
            .docComment
        case .dollarIdentifier, .identifier:
            .identifier
        case .editorPlaceholder:
            .placeholder
        case .floatLiteral, .integerLiteral:
            .number
        case .ifConfigDirective:
            .poundDirectiveKeyword
        case .keyword:
            .keyword
        case .none, .regexLiteral:
            nil
        case .operator:
            .operator
        case .stringLiteral:
            .string
        case .type:
            .typeidentifier
        case .argumentLabel:
            .argument
        @unknown default:
            nil
        }
    }

    /// Convert SwiftSyntax syntax classifications to SourceKitten-compatible syntax tokens.
    public static func sourceKittenSyntaxKinds(for file: SwiftLintFile) -> [SwiftLintSyntaxToken] {
        file.syntaxClassifications.compactMap { classifiedRange in
            guard let syntaxKind = mapClassification(classifiedRange.kind) else {
                return nil
            }

            let byteRange = classifiedRange.range.toSourceKittenByteRange()
            let token = SyntaxToken(
                type: syntaxKind.rawValue,
                offset: byteRange.location,
                length: byteRange.length
            )

            return SwiftLintSyntaxToken(value: token)
        }
    }
}
