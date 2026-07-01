internal struct InclusiveLanguageRuleExamples {
    // MARK: - Default config

    static let nonTriggeringExamples: [Example] = #examples([
        "let foo = \"abc\"",
        """
        enum AllowList {
            case foo, bar
        }
        """,
        "func updateAllowList(add: String) {}",
        """
        enum WalletItemType {
            case visa
            case mastercard
        }
        """,
        "func chargeMasterCard(_ card: Card) {}",
    ])

    static let triggeringExamples: [Example] = #examples([
        "let ↓slave = \"abc\"",
        """
        enum ↓BlackList {
            case foo, bar
        }
        """,
        "func ↓updateWhiteList(add: String) {}",
        """
        enum ListType {
            case ↓whitelist
            case ↓blacklist
        }
        """,
        "init(↓master: String, ↓slave: String) {}",
        """
        final class FooBar {
            func register<↓Master, ↓Slave>(one: Master, two: Slave) {}
        }
        """,
    ])

    // MARK: - Non-default config

    static let nonTriggeringExamplesWithConfig: [Example] = [
        """
        let blackList = [
            "foo", "bar"
        ]
        """.configuration([
            "override_terms": ["abc123"]
        ]),
        """
        private func doThisThing() {}
        """.configuration([
            "override_terms": ["abc123"],
            "additional_terms": ["xyz789"],
        ]),
    ]

    static let triggeringExamplesWithConfig: [Example] = [
        """
        enum Things {
            case foo, ↓fizzBuzz
        }
        """.configuration([
            "additional_terms": ["fizzbuzz"]
        ]),
        """
        private func ↓thisIsASwiftyFunction() {}
        """.configuration([
            "additional_terms": ["swift"]
        ]),
        """
        private var ↓fooBar = "abc"
        """.configuration([
            "additional_terms": ["FoObAr"]
        ]),
    ]
}
