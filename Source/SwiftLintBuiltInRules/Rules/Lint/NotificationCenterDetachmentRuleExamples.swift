internal struct NotificationCenterDetachmentRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        class Foo {
           deinit {
               NotificationCenter.default.removeObserver(self)
           }
        }
        """),
        Example("""
        class Foo {
           func bar() {
               NotificationCenter.default.removeObserver(otherObject)
           }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        class Foo {
           func bar() {
               ↓NotificationCenter.default.removeObserver(self)
           }
        }
        """)
    ]
}
