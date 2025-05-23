struct IfSwitchExpressionRuleExamples {
    static let nonTriggeringExamples: [Example] = [
        Example("let result = if condition { true } else { false }"),
        Example("""
        func f(cond: Bool) -> Int {
            if cond {
                // Nothing
            } else {
                return 2
            }
            return 1
        }
        """),
        Example("""
        func f(cond: Bool) -> Int {
            let result = if cond { 1 } else { 2 }
            return result
        }
        """),
        Example("""
        let value = 3
        let description = switch value {
            case 1 -> "one"
            case 2 -> "two"
            default -> "other"
        }
        """),
        Example("""
        func g(value: Int) -> String {
            return switch value {
                case 1 -> "one"
                case 2 -> "two"
                default -> "other"
            }
        }
        """),
        Example("""
        let result = switch number {
            case 1 -> "one"
            case 2 -> "two"
            case 3 -> "three"
            default -> "unknown"
        }
        """),
        Example("""
        func calculate(value: Int) -> Int {
            return switch value {
                case 1 -> 10
                case 2 -> 20
                case 3 -> 30
                default -> 0
            }
        }
        """)
    ]

    static let triggeringExamples: [Example] = [
        Example("""
        func f(cond: Bool) {
            let r: Int
            if cond {
                r = 1
            } else {
                r = 2
            }
        }
        """),
        Example("""
        func f(cond: Bool) -> Int {
            if cond {
                return 1
            } else {
                return 2
            }
        }
        """),
        Example("""
        func f(cond: Bool) -> Int {
            if cond {
                // Nothing
            } else {
                return 2
            }
            return 1
        }
        """),
        Example("""
        let result: String
        if condition {
            result = "yes"
        } else {
            result = "no"
        }
        """),
        Example("""
        func g(value: Int) -> String {
            let result: String
            switch value {
                case 1:
                    result = "one"
                case 2:
                    result = "two"
                default:
                    result = "other"
            }
            return result
        }
        """),
        Example("""
        func calculate(value: Int) -> Int {
            if value == 1 {
                return 10
            } else if value == 2 {
                return 20
            } else {
                return 0
            }
        }
        """),
        Example("""
        let result: Int
        if value == 1 {
            result = 10
        } else if value == 2 {
            result = 20
        } else {
            result = 0
        }
        """),
        Example("""
        let description: String
        switch number {
            case 1:
                description = "one"
            case 2:
                description = "two"
            case 3:
                description = "three"
            default:
                description = "unknown"
        }
        """)
    ]
}
