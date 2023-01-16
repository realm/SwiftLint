internal struct InclusiveLanguageRuleExamples {
    // MARK: - Default config

    static let nonTriggeringExamples: [Example] = [
        Example("let foo = \"abc\""),
        Example("""
        enum AllowList {
            case foo, bar
        }
        """),
        Example("func updateAllowList(add: String) {}"),
        Example("""
        enum WalletItemType {
            case visa
            case mastercard
        }
        """),
        Example("func chargeMasterCard(_ card: Card) {}")
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
        Example("init(↓master: String, ↓slave: String) {}"),
        Example("""
        final class FooBar {
            func register<↓Master, ↓Slave>(one: Master, two: Slave) {}
        }
        """)
    ]

    // MARK: - Non-default config

    static let nonTriggeringExamplesWithConfig: [Example] = [
        Example("""
        let blackList = [
            "foo", "bar"
        ]
        """, configuration: [
            "override_terms": ["abc123"]
        ]),
        Example("""
        private func doThisThing() {}
        """, configuration: [
            "override_terms": ["abc123"],
            "additional_terms": ["xyz789"]
        ])
    ]

    static let triggeringExamplesWithConfig: [Example] = [
        Example("""
        enum Things {
            case foo, ↓fizzBuzz
        }
        """, configuration: [
            "additional_terms": ["fizzbuzz"]
        ]),
        Example("""
        private func ↓thisIsASwiftyFunction() {}
        """, configuration: [
            "additional_terms": ["swift"]
        ]),
        Example("""
        private var ↓fooBar = "abc"
        """, configuration: [
            "additional_terms": ["FoObAr"]
        ])
    ]
}
