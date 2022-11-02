import Foundation

/// A SwiftLint-interpretable command to modify SwiftLint's behavior embedded as comments in source code.
public struct Command: Equatable {
    /// The action (verb) that SwiftLint should perform when interpreting this command.
    public enum Action: String {
        /// The rule(s) associated with this command should be enabled by the SwiftLint engine.
        case enable
        /// The rule(s) associated with this command should be disabled by the SwiftLint engine.
        case disable

        /// - returns: The inverse action that can cancel out the current action, restoring the SwifttLint engine's
        ///            state prior to the current action.
        internal func inverse() -> Action {
            switch self {
            case .enable: return .disable
            case .disable: return .enable
            }
        }
    }

    /// The modifier for a command, used to modify its scope.
    public enum Modifier: String {
        /// The command should only apply to the line preceding its definition.
        case previous
        /// The command should only apply to the same line as its definition.
        case this
        /// The command should only apply to the line following its definition.
        case next
    }

    /// Text after this delimiter is not considered part of the rule.
    /// The purpose of this delimiter is to allow SwiftLint
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

    /// Creates a command based on the specified parameters.
    ///
    /// - parameter action:          This command's action.
    /// - parameter ruleIdentifiers: The identifiers for the rules associated with this command.
    /// - parameter line:            The line in the source file where this command is defined.
    /// - parameter character:       The character offset within the line in the source file where this command is
    ///                              defined.
    /// - parameter modifier:        This command's modifier, if any.
    /// - parameter trailingComment: The comment following this command's `-` delimiter, if any.
    public init(action: Action, ruleIdentifiers: Set<RuleIdentifier>, line: Int = 0,
                character: Int? = nil, modifier: Modifier? = nil, trailingComment: String? = nil) {
        self.action = action
        self.ruleIdentifiers = ruleIdentifiers
        self.line = line
        self.character = character
        self.modifier = modifier
        self.trailingComment = trailingComment
    }

    /// Creates a command based on the specified parameters.
    ///
    /// - parameter actionString: The string in the command's definition describing its action.
    /// - parameter line:         The line in the source file where this command is defined.
    /// - parameter character:    The character offset within the line in the source file where this command is
    ///                           defined.
    public init?(actionString: String, line: Int, character: Int) {
        let scanner = Scanner(string: actionString)
        _ = scanner.scanString("swiftlint:")
        // (enable|disable)(:previous|:this|:next)
        guard let actionAndModifierString = scanner.scanUpToString(" ") else {
            return nil
        }
        let actionAndModifierScanner = Scanner(string: actionAndModifierString)
        guard let actionString = actionAndModifierScanner.scanUpToString(":"),
            let action = Action(rawValue: actionString)
            else {
                return nil
        }
        self.action = action
        self.line = line
        self.character = character

        let rawRuleTexts = scanner.scanUpToString(Self.commentDelimiter) ?? ""
        if scanner.isAtEnd {
            trailingComment = nil
        } else {
            // Store any text after the comment delimiter as the trailingComment.
            // The addition to currentIndex is to move past the delimiter
            trailingComment = String(
              scanner
                .string[scanner.currentIndex...]
                .dropFirst(Self.commentDelimiter.count)
            )
        }
        let ruleTexts = rawRuleTexts.components(separatedBy: .whitespacesAndNewlines).filter {
            let component = $0.trimmingCharacters(in: .whitespaces)
            return component.isNotEmpty && component != "*/"
        }

        ruleIdentifiers = Set(ruleTexts.map(RuleIdentifier.init(_:)))

        // Modifier
        let hasModifier = actionAndModifierScanner.scanString(":") != nil
        if hasModifier {
            modifier = Modifier(
              rawValue: String(
                actionAndModifierScanner.string[actionAndModifierScanner.currentIndex...]
              )
            )
        } else {
            modifier = nil
        }
    }

    /// Expands the current command into its fully descriptive form without any modifiers.
    /// If the command doesn't have a modifier, it is returned as-is.
    ///
    /// - returns: The expanded commands.
    internal func expand() -> [Command] {
        guard let modifier = modifier else {
            return [self]
        }
        switch modifier {
        case .previous:
            return [
                Self(action: action, ruleIdentifiers: ruleIdentifiers, line: line - 1),
                Self(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line - 1, character: Int.max)
            ]
        case .this:
            return [
                Self(action: action, ruleIdentifiers: ruleIdentifiers, line: line),
                Self(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line, character: Int.max)
            ]
        case .next:
            return [
                Self(action: action, ruleIdentifiers: ruleIdentifiers, line: line + 1),
                Self(action: action.inverse(), ruleIdentifiers: ruleIdentifiers, line: line + 1, character: Int.max)
            ]
        }
    }
}
