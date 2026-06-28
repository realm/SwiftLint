internal struct NotificationCenterDetachmentRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        class Foo {
           deinit {
               NotificationCenter.default.removeObserver(self)
           }
        }
        """,
        """
        class Foo {
           func bar() {
               NotificationCenter.default.removeObserver(otherObject)
           }
        }
        """,
    ])

    static let triggeringExamples = #examples([
        """
        class Foo {
           func bar() {
               ↓NotificationCenter.default.removeObserver(self)
           }
        }
        """,
    ])
}
