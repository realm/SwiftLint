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
    ]

    static let triggeringExamples = [
        Example("""
        func f(cond: Bool) -> Int {
            ↓if cond {
                return 1
            } else if self.otherCond {
                return 2
            } else {
                return 3
            }
        }
        """),
        Example("""
        func f(cond: Bool) {
            let r: Int
            ↓if cond {
                r = 1
            } else {
                // Some comment
                r = 2
            }
        }
        """),
        Example("""
        func test(x: Int) throws -> String {
            ↓switch x {
            case 1:
                return "One"
            case 2:
                return "Two"
            default:
                return "More"
            }
        }
        """),
        Example("""
        func test(x: Int) throws -> String {
            ↓switch x {
            case 1:
                return "One"
            case 2:
                return "Two"
            default:
                throw TestError.test
            }
        }
        """),
        Example("""
        init(rawValue: String) throws {
            ↓switch rawValue {
            case "lemon": self = .lemon
            case "lime": self = .lime
            default: throw TestError.test
            }
        }
        """),
    ]
}
