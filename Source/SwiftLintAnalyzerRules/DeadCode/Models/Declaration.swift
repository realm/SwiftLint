/// A source code declaration.
struct Declaration: Comparable, Hashable {
    enum Kind {
        /// This declaration is an instance property.
        case instanceProperty
        /// This declaration is an instance method.
        case instanceMethod
        /// This declaration is a class.
        case `class`
        /// This declaration is an enum case.
        case enumCase
        /// This declaration is an initializer.
        case initializer
    }

    /// The unique symbol resolution ID for this declaration.
    let usr: String
    /// The file path where this declaration is defined.
    let file: String
    /// The line where this declaration is defined.
    let line: Int
    /// The column where this declaration is defined.
    let column: Int
    /// The Swift name for this declaration.
    let name: String
    /// The Swift module for this declaration.
    let module: String
    /// This kind of the symbol for the declaration.
    let kind: Kind?

    static func < (lhs: Declaration, rhs: Declaration) -> Bool {
        return (lhs.file, lhs.line, lhs.column, lhs.usr) < (rhs.file, rhs.line, rhs.column, rhs.usr)
    }
}
