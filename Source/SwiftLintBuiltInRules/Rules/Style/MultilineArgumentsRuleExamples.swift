internal struct MultilineArgumentsRuleExamples {
    static let nonTriggeringExamples = [
        Example("foo()"),
        Example("foo(\n" +
                    ")"),
        Example("foo { }"),
        Example("foo {\n" +
        "    \n" +
        "}"),
        Example("foo(0)"),
        Example("foo(0, 1)"),
        Example("foo(0, 1) { }"),
        Example("foo(0, param1: 1)"),
        Example("foo(0, param1: 1) { }"),
        Example("foo(param1: 1)"),
        Example("foo(param1: 1) { }"),
        Example("foo(param1: 1, param2: true) { }"),
        Example("foo(param1: 1, param2: true, param3: [3]) { }"),
        Example("""
        foo(param1: 1, param2: true, param3: [3]) {
            bar()
        }
        """),
        Example("""
        foo(param1: 1,
            param2: true,
            param3: [3])
        """),
        Example("""
        foo(
            param1: 1, param2: true, param3: [3]
        )
        """),
        Example("""
        foo(
            param1: 1,
            param2: true,
            param3: [3]
        )
        """)
    ]

    static let triggeringExamples = [
        Example("""
        foo(0,
            param1: 1, ↓param2: true, ↓param3: [3])
        """),
        Example("""
        foo(0, ↓param1: 1,
            param2: true, ↓param3: [3])
        """),
        Example("""
        foo(0, ↓param1: 1, ↓param2: true,
            param3: [3])
        """),
        Example("""
        foo(
            0, ↓param1: 1,
            param2: true, ↓param3: [3]
        )
        """)
    ]
}
