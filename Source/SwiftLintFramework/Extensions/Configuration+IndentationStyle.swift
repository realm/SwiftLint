public extension Configuration {
    /// The style of indentation used in a Swift project.
    enum IndentationStyle: Hashable {
        /// Swift source code should be indented using tabs.
        case tabs
        /// Swift source code should be indented using spaces with `count` spaces per indentation level.
        case spaces(count: Int)

        /// The default indentation style if none is explicitly provided.
        static var `default` = spaces(count: 4)

        /// Creates an indentation style based on an untyped configuration value.
        ///
        /// - parameter object: The configuration value.
        internal init?(_ object: Any?) {
            switch object {
            case let value as Int: self = .spaces(count: value)
            case let value as String where value == "tabs": self = .tabs
            default: return nil
            }
        }
    }
}
