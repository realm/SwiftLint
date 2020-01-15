internal struct MultilineArgumentsRuleExamples {
    static let nonTriggeringExamples = [
        "foo()",
        Example("foo(\n" +
                    ")"),
        "foo { }",
        Example("foo {\n" +
        "    \n" +
        "}"),
        "foo(0)",
        "foo(0, 1)",
        "foo(0, 1) { }",
        "foo(0, param1: 1)",
        "foo(0, param1: 1) { }",
        "foo(param1: 1)",
        "foo(param1: 1) { }",
        "foo(param1: 1, param2: true) { }",
        "foo(param1: 1, param2: true, param3: [3]) { }",
        Example("foo(param1: 1, param2: true, param3: [3]) {\n" +
        "    bar()\n" +
        "}"),
        Example("foo(param1: 1,\n" +
        "    param2: true,\n" +
        "    param3: [3])"),
        Example("foo(\n" +
        "    param1: 1, param2: true, param3: [3]\n" +
        ")"),
        Example("foo(\n" +
        "    param1: 1,\n" +
        "    param2: true,\n" +
        "    param3: [3]\n" +
        ")")
    ]

    static let triggeringExamples = [
        Example("foo(0,\n" +
        "    param1: 1, ↓param2: true, ↓param3: [3])"),
        Example("foo(0, ↓param1: 1,\n" +
        "    param2: true, ↓param3: [3])"),
        Example("foo(0, ↓param1: 1, ↓param2: true,\n" +
        "    param3: [3])"),
        Example("foo(\n" +
        "    0, ↓param1: 1,\n" +
        "    param2: true, ↓param3: [3]\n" +
        ")")
    ]
}
