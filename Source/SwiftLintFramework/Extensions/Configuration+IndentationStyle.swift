public extension Configuration {
    enum IndentationStyle: Equatable {
        case tabs
        case spaces(count: Int)

        public static var `default` = spaces(count: 4)

        internal init?(_ object: Any?) {
            switch object {
            case let value as Int: self = .spaces(count: value)
            case let value as String where value == "tabs": self = .tabs
            default: return nil
            }
        }
    }
}
