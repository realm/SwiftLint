import SwiftIDEUtils

public extension SyntaxClassification {
    // True if it is any kind of comment.
    var isComment: Bool {
        switch self {
        case .lineComment, .docLineComment, .blockComment, .docBlockComment:
            return true
        case .none, .keyword, .identifier, .typeIdentifier, .operatorIdentifier, .dollarIdentifier, .integerLiteral,
             .floatLiteral, .stringLiteral, .stringInterpolationAnchor, .poundDirective, .buildConfigId,
             .attribute, .editorPlaceholder, .regexLiteral:
            return false
        }
    }
}
