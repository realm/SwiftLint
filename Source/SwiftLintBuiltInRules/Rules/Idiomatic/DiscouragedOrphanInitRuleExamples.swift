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
        """),
        Example("""
        callSomething(
            parameter: Foobar.init(
                parameter: 42
            )
        )
        """),
        Example("""
        someClosure {
            Foobar.init()
        }
        """),
        Example("""
        someClosure { _ in
            Foobar.init(parameter: 42)
        }
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
        """),
        Example("""
        callSomething(
            parameter: ↓.init(
                parameter: 42
            )
        )
        """),
        Example("""
        someClosure {
            ↓.init()
        }
        """),
        Example("""
        someClosure { _ in
            ↓.init(parameter: 42)
        }
        """)
    ]
}
