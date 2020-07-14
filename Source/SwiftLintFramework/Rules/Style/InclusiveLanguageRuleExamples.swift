internal struct InclusiveLanguageRuleExamples {

    // MARK: - Default config

    static let nonTriggeringExamples: [Example] = [
        Example("let foo = \"abc\""),
        Example("""
        enum AllowList {
            case foo, bar
        }
        """),
        Example("func updateAllowList(add: String) {}")
    ]

    static let triggeringExamples: [Example] = [
        Example("let ↓slave = \"abc\""),
        Example("""
        enum ↓BlackList {
            case foo, bar
        }
        """),
        Example("func ↓updateWhiteList(add: String) {}"),
        Example("""
        enum ListType {
            case ↓whitelist
            case ↓blacklist
        }
        """),
        Example("↓init(master: String, slave: String) {}"),
        Example("""
        final class FooBar {
            func register<↓Master, ↓Slave>(one: Master, two: Slave) {}
        }
        """)
    ]

    // MARK: - Non-default config

    static let nonTriggeringExamplesWithNonDefaultConfig: [Example] = [
        Example("""
        public let blackList = [
            "foo", "bar"
        ]
        """, configuration: [
            "allow": ["blacklist"]
        ]),
        Example("""
        private func doThisThing() {}
        """, configuration: [
            "deny": ["thing"],
            "allow": ["thing"]
        ])
    ]

    static let triggeringExamplesWithNonDefaultConfig: [Example] = [
        Example("""
        enum Things {
            case foo, ↓fizzBuzz
        }
        """, configuration: [
            "deny": ["fizzbuzz"]
        ]),
        Example("""
        private func ↓thisIsASwiftyFunction() {}
        """, configuration: [
            "deny": ["swift"]
        ]),
        Example("""
        private var ↓fooBar = "abc"
        """, configuration: [
            "deny": ["FoObAr"]
        ])
    ]
}
