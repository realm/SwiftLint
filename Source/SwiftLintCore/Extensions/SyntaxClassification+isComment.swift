import SwiftIDEUtils

public extension SyntaxClassification {
    // True if it is any kind of comment.
    var isComment: Bool {
        switch self {
        case .lineComment, .docLineComment, .blockComment, .docBlockComment:
            return true
        case .none, .keyword, .identifier, .type, .operator, .dollarIdentifier, .integerLiteral, .argumentLabel,
             .floatLiteral, .stringLiteral, .ifConfigDirective, .attribute, .editorPlaceholder, .regexLiteral:
            return false
        }
    }
}
