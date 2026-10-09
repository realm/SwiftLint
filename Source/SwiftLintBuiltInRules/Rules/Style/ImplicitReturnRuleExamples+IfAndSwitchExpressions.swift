import SwiftLintCore

extension ImplicitReturnRuleExamples {
    struct IfAndSwitchExpressionExamples {
        private static let configuration: [String: any Sendable] = ["check_if_and_switch_expressions": true]

        static let nonTriggeringExamples = #examples([
            """
            func f() -> Int {
                if condition {
                    return 1
                } else {
                    return 2
                }
            }
            """.asExample(),
            """
            func f() -> Int {
                if condition { 1 } else { 2 }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> Int? {
                if condition {
                    return 1
                }
                return nil
            }
            """.asExample(configuration: configuration),
            """
            func f() {
                if condition {
                    return
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() {
                if condition {
                    return
                } else {
                    return
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> Int {
                if condition {
                    let x = 1
                    return x
                } else {
                    return 2
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> Int {
                if condition {
                    return 1
                } else {
                    throw MyError()
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> Int {
                if a {
                    return 1
                } else if b {
                    return 2
                }
                return 3
            }
            """.asExample(configuration: configuration),
            """
            func f() -> String {
                switch value {
                case 0:
                    return "zero"
                default:
                    print("other")
                    return "other"
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> String {
                switch value {
                case 0:
                    return "zero"
                #if DEBUG
                default:
                    return "debug"
                #else
                default:
                    return "release"
                #endif
                }
            }
            """.asExample(configuration: configuration),
            """
            foo.map { value in
                if value {
                    return 1
                } else {
                    return 2
                }
            }
            """.asExample(configuration: configuration),
            """
            let f = { (x: Int) in
                switch x {
                case 0: return Optional(1)
                default: return nil
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> Int {
                label: switch value {
                case 0: return 1
                default: return 2
                }
            }
            """.asExample(configuration: configuration),
        ])

        static let triggeringExamples = #examples([
            """
            func f() -> Int {
                if condition {
                    ↓return 1
                } else {
                    ↓return 2
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> Int {
                if a {
                    ↓return 1
                } else if b {
                    ↓return 2
                } else {
                    ↓return 3
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> String {
                switch value {
                case 0:
                    ↓return "zero"
                case 1:
                    ↓return "one"
                @unknown default:
                    ↓return "other"
                }
            }
            """.asExample(configuration: configuration),
            """
            func f() -> String {
                switch value {
                case 0:
                    if condition {
                        ↓return "zero"
                    } else {
                        ↓return "nil"
                    }
                default:
                    ↓return "other"
                }
            }
            """.asExample(configuration: configuration),
            """
            var foo: Int {
                if condition {
                    switch value {
                    case 0: ↓return 0
                    default: ↓return 1
                    }
                } else {
                    ↓return 2
                }
            }
            """.asExample(configuration: configuration),
            """
            foo.map { value -> Int in
                if value {
                    ↓return 1
                } else {
                    ↓return 2
                }
            }
            """.asExample(configuration: configuration),
        ])

        static let corrections = #corrections([
            """
            func f() -> Int {
                if condition {
                    // Comment
                    return 1
                } else {
                    return 2
                }
            }
            """.asExample(configuration: configuration): """
                func f() -> Int {
                    if condition {
                        // Comment
                        1
                    } else {
                        2
                    }
                }
                """,
            """
            func f() -> String {
                switch value {
                case 0: return "zero"
                default:
                    if condition {
                        return "one"
                    } else {
                        return "other"
                    }
                }
            }
            """.asExample(configuration: configuration): """
                func f() -> String {
                    switch value {
                    case 0: "zero"
                    default:
                        if condition {
                            "one"
                        } else {
                            "other"
                        }
                    }
                }
                """,
            """
            let f = { (x: Int) -> Int? in
                switch x {
                case 0: return 1
                default: return nil
                }
            }
            """.asExample(configuration: configuration): """
                let f = { (x: Int) -> Int? in
                    switch x {
                    case 0: 1
                    default: nil
                    }
                }
                """,
        ])
    }
}
