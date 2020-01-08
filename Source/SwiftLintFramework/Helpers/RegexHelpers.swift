struct RegexHelpers {
    /// A single variable
    static let varName = "[a-zA-Z_][a-zA-Z0-9_]+"

    /// A single variable in a group (capturable)
    static let varNameGroup = "\\s*(\(varName))\\s*"

    /// Two variables (capturables)
    static let twoVars = "\(varNameGroup),\(varNameGroup)"

    /// A number
    static let number = "[\\-0-9\\.]+"

    /// A variable or a number (capturable)
    static let variableOrNumber = "\\s*(\(varName)|\(number))\\s*"

    /// Two 'variable or number'
    static let twoVariableOrNumber = "\(variableOrNumber),\(variableOrNumber)"
}
