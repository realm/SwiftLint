struct RegexHelpers {
    /// A single variable
    static let varName = "[a-zA-Z_][a-zA-Z0-9_]+"

    /// A number
    static let number = "[\\-0-9\\.]+"

    /// A variable or a number (capturable)
    static let variableOrNumber = "\\s*(\(varName)|\(number))\\s*"
}
