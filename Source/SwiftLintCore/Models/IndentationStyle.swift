/// The style of indentation used in a Swift project.
public enum IndentationStyle: Hashable, Sendable {
    /// Swift source code should be indented using tabs.
    case tabs
    /// Swift source code should be indented using spaces with `count` spaces per indentation level.
    case spaces(count: Int)

    /// The default indentation style if none is explicitly provided.
    package static let `default` = spaces(count: 4)

    /// The string representation of one level of indentation.
    public var indentationString: String {
        switch self {
        case .tabs: return "\t"
        case .spaces(let count): return String(repeating: " ", count: count)
        }
    }

    /// The indentation string for the given number of levels.
    public func indentation(for levels: Int) -> String {
        String(repeating: indentationString, count: max(levels, 0))
    }

    /// Counts the indentation level represented by a raw whitespace string.
    public func levelCount(in rawIndent: String) -> Int {
        let tabs = rawIndent.filter { $0 == "\t" }.count
        let spaces = rawIndent.filter { $0 == " " }.count
        let spacesPerLevel: Int
        switch self {
        case .tabs: spacesPerLevel = 4
        case .spaces(let count): spacesPerLevel = count
        }
        return tabs + spaces / spacesPerLevel
    }

    /// Creates an indentation style based on an untyped configuration value.
    ///
    /// - parameter object: The configuration value.
    package init?(_ object: Any?) {
        switch object {
        case let value as Int: self = .spaces(count: value)
        case let value as String where value == "tabs": self = .tabs
        default: return nil
        }
    }
}
