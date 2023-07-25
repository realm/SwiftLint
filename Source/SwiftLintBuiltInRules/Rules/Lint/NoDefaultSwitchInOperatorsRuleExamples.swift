struct NoDefaultSwitchInOperatorsRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
func foo() {}
"""),
        Example("""
func foo(lhs: Bar, rhs: Bar) -> Bool {
    return lhs == rhs
}
"""),

        Example("""
func ==(lhs: Bar, rhs: Bar) -> Bool {
    switch (lhs, rhs) {
    case (.baz, .baz):
        return true
    case (.baz, _), (.qux, _):
        return false
    }
}
"""),
        Example("""
func ==(lhs: Bar, rhs: Bar) -> Bool {
    switch (lhs, rhs) {
    case (.baz, .baz):
        return true
    @unknown default:
        return false
    }
}
""")
    ]

    static let triggeringExamples = [
        Example("""
func ==(lhs: Bar, rhs: Bar) -> Bool {
    switch (lhs, rhs) {
    case (.baz, .baz):
        return true
    default:
        return false
    }
}
"""),
        Example("""
func >(lhs: Bar, rhs: Bar) -> Bool {
    switch (lhs, rhs) {
    case (.baz, .baz):
        return true
    default:
        return false
    }
}
""")
    ]
}
