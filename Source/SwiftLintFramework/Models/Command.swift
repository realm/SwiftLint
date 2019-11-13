import Foundation
import SourceKittenFramework

#if os(Linux)
private extension Scanner {
    func scanString(string: String) -> String? {
        return scanString(string)
    }
}
#else
private extension Scanner {
    func scanUpToString(_ string: String) -> String? {
        var result: NSString?
        let success = scanUpTo(string, into: &result)
        if success {
            return result?.bridge()
        }
        return nil
    }

    func scanString(string: String) -> String? {
        var result: NSString?
        let success = scanString(string, into: &result)
        if success {
            return result?.bridge()
        }
        return nil
    }
}
#endif

public struct Command: Equatable {
    public enum Action: String {
        case enable
        case disable

        internal func inverse() -> Action {
            switch self {
            case .enable: return .disable
            case .disable: return .enable
            }
        }
    }

    public enum Modifier: String {
        case previous
        case this
        case next
    }

    /// Text after this delimiter is not considered part of the rule.
    /// The purpose of this delimiter is to allow swiftlint
    /// commands to be documented in source code.
    ///
    ///     swiftlint:disable:next force_try - Explanation here
    private static let commentDelimiter = " - "

    internal let action: Action
    internal let ruleIdentifiers: Set<RuleIdentifier>
    internal let line: Int
    internal let character: Int?
    internal let modifier: Modifier?
    /// Currently unused but parsed separate from rule identifiers
    internal let trailingComment: String?

    public init(action: Action, ruleIdentifiers: Set<RuleIdentifier>, line: Int = 0,
                character: Int? = nil, modifier: Modifier? = nil, trailingComment: String? = nil) {
        self.action = action
        self.ruleIdentifiers = ruleIdentifiers
        self.line = line
        self.character = character
        self.modifier = modifier
        self.trailingComment = trailingComment
    }

    public init?(string: NSString, range: NSRange) {
        let scanner = Scanner(string: string.substring(with: range))
        _ = scanner.scanString(string: "swiftlint:")
        // (enable|disable)(:previous|:this|:next)
        guard let actionAndModifierString = scanner.scanUpToString(" ") else {
            return nil
        }
        let actionAndModifierScanner = Scanner(string: actionAndModifierString)
        guard let actionString = actionAndModifierScanner.scanUpToString(":"),
            let action = Action(rawValue: actionString),
            let lineAndCharacter = StringLinesContainer(string).lineAndCharacter(forCharacterOffset: NSMaxRange(range))
            else {
                return nil
        }
        self.action = action
        line = lineAndCharacter.line
        character = lineAndCharacter.character

        let rawRuleTexts = scanner.scanUpToString(Command.commentDelimiter) ?? ""
        if scanner.isAtEnd {
            trailingComment = nil
        } else {
            // Store any text after the comment delimiter as the trailingComment.
            // The addition to scanLocation is to move past the delimiter
            let startOfCommentPastDelimiter = scanner.scanLocation + Command.commentDelimiter.count
            trailingComment = scanner.string.bridge().substring(from: startOfCommentPastDelimiter)
        }
        let ruleTexts = rawRuleTexts.components(separatedBy: .whitespaces).filter {
            let component = $0.trimmingCharacters(in: .whitespaces)
            return !component.isEmpty && component != "*/"
        }

        ruleIdentifiers = Set(ruleTexts.map(RuleIdentifier.init(_:)))

        // Modifier
        let hasModifier = actionAndModifierScanner.scanString(string: ":") != nil
        if hasModifier {
            let modifierString = actionAndModifierScanner.string.bridge()
                .substring(from: actionAndModifierScanner.scanLocation)
            modifier = Modifier(rawValue: modifierString)
        } else {
            modifier = nil
        }
    }

    internal func expand() -> [Command] {
        guard let modifier = modifier else {
            return [self]
        }
        switch modifier {
        case .previous:
            return [
                Command(action: action, ruleIdentifiers: ruleIdentifiers, line: line - 1),
                Command(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line - 1,
                        character: Int.max)
            ]
        case .this:
            return [
                Command(action: action, ruleIdentifiers: ruleIdentifiers, line: line),
                Command(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line,
                        character: Int.max)
            ]
        case .next:
            return [
                Command(action: action, ruleIdentifiers: ruleIdentifiers, line: line + 1),
                Command(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line + 1, character: Int.max)
            ]
        }
    }
}
