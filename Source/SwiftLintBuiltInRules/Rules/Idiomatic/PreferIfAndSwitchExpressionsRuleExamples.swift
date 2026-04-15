internal struct PreferIfAndSwitchExpressionsRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        if cond {
            // Nothing
        } else {
            return 2
        }
        return 1
        """),
        Example("""
        if cond {
            print("Hey")
            return 1
        } else {
            return 2
        }
        """),
        Example("""
        return if cond {
            1
        } else {
            2
        }
        """),
        Example("""
        if cond {
            return 1
        } else {
            throw TestError.test
        }
        """),
        Example("""
        let x = switch value {
        case 1:
            "One"
        case 2:
            "Two"
        default:
            fatalError()
        }
        """),
        Example("""
        if value {
            self.x = "One"
        } else {
            x = "Two"
        }
        """),
        Example("""
        if value {
            x = "One"
        } else {
            y = "Two"
        }
        """),
        Example("""
        switch value {
        case 1:
            x = "One"
        case 2:
            y = "Two"
        default:
            z = "Three"
        }
        """),
        Example("""
        if value {
            x = "One"
        } else if otherValue {
            y = "Two"
        }
        """),
        Example("""
        throw if cond {
            error1
        } else if self.otherCond {
            error2
        } else {
            error3
        }
        """),
    ]

    static let triggeringExamples = [
        Example("""
        ↓if cond {
            return 1
        } else if self.otherCond {
            return 2
        } else {
            return 3
        }
        """),
        Example("""
        let r: Int
        ↓if cond {
            r = 1 + 2
        } else {
            // Some comment
            r = 2
        }
        """),
        Example("""
        ↓if value {
            self.x = "One"
        } else {
            self.x = "Two"
        }
        """),
        Example("""
        ↓if cond {
            (a, b) = (1, 2)
        } else {
            (a, b) = (3, 4)
        }
        """),
        Example("""
        ↓if cond {
            object?.value = 1
        } else {
            object?.value = 2
        }
        """).focused(),
        Example("""
        ↓if cond {
            dict[key] = 1
        } else {
            dict[key] = 1
        }
        """).focused(),
        Example("""
        ↓switch x {
        case 1:
            return try await foo()
        case 2:
            return "Two"
        default:
            return "More"
        }
        """),
        Example("""
        ↓switch x {
        case 1:
            return "One"
        case 2:
            return "Two"
        default:
            throw TestError.test
        }
        """),
        Example("""
        ↓switch rawValue {
        case "lemon": self = .lemon
        case "lime": self = .lime
        default: throw TestError.test
        }
        """),
        Example("""
        if x {
            ↓if y {
                r = 1 + 2
            } else {
                // Some comment
                r = 2
            }
        }
        """),
        Example("""
        ↓if cond {
            throw error1
        } else if self.otherCond {
            throw error2
        } else {
            throw error3
        }
        """),
    ]
}
