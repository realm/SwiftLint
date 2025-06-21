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
            return .attributeID
        case .blockComment, .lineComment:
            return .comment
        case .docBlockComment, .docLineComment:
            return .docComment
        case .dollarIdentifier, .identifier:
            return .identifier
        case .editorPlaceholder:
            return .placeholder
        case .floatLiteral, .integerLiteral:
            return .number
        case .ifConfigDirective:
            return .poundDirectiveKeyword
        case .keyword:
            return .keyword
        case .none, .regexLiteral:
            return nil
        case .operator:
            return .operator
        case .stringLiteral:
            return .string
        case .type:
            return .typeidentifier
        case .argumentLabel:
            return .argument
        @unknown default:
            return nil
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
