internal struct DiscouragedOrphanInitRuleExamples {
    static let nonTriggeringExamples = [
        Example("callSomething(Foobar.init())"),
        Example("callSomething(Foobar.init(parameter: 42))"),
        Example("""
        callSomething(
            parameter: Foobar.init()
        )
        """),
        Example("""
        callSomething(
            Foobar.init(parameter: 42)
        )
        """)
    ]

    static let triggeringExamples = [
        Example("callSomething(↓.init())"),
        Example("callSomething(↓.init(parameter: 42))"),
        Example("""
        callSomething(
            parameter: ↓.init()
        )
        """),
        Example("""
        callSomething(
            ↓.init(parameter: 42)
        )
        """)
    ]
}
