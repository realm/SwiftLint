internal struct MultilineArgumentsRuleExamples {
    static let nonTriggeringExamples = #examples([
        "foo()",
        """
        foo(
        )
        """,
        "foo { }",
        """
        foo {

        }
        """,
        "foo(0)",
        "foo(0, 1)",
        "foo(0, 1) { }",
        "foo(0, param1: 1)",
        "foo(0, param1: 1) { }",
        "foo(param1: 1)",
        "foo(param1: 1) { }",
        "foo(param1: 1, param2: true) { }",
        "foo(param1: 1, param2: true, param3: [3]) { }",
        """
        foo(param1: 1, param2: true, param3: [3]) {
            bar()
        }
        """,
        """
        foo(param1: 1,
            param2: true,
            param3: [3])
        """,
        """
        foo(
            param1: 1, param2: true, param3: [3]
        )
        """,
        """
        foo(
            param1: 1,
            param2: true,
            param3: [3]
        )
        """,
        #"""
        Picker(selection: viewStore.binding(\.$someProperty)) {
           ForEach(SomeEnum.allCases, id: \.rawValue) { someCase in
              Text(someCase.rawValue)
                 .tag(someCase)
           }
        } label: {
           EmptyView()
        }
        """#,
        """
        UIView.animate(withDuration: 1,
                       delay: 0) {
            // sample
            print("a")
        } completion: { _ in
            // sample
            print("b")
        }
        """,
        """
        UIView.animate(withDuration: 1, delay: 0) {
            print("a")
        } completion: { _ in
            print("b")
        }
        """,
        """
        f(
            foo: 1,
            bar: false,
        )
        """,
    ])

    static let triggeringExamples = #examples([
        """
        foo(0,
            param1: 1, ↓param2: true, ↓param3: [3])
        """,
        """
        foo(0, ↓param1: 1,
            param2: true, ↓param3: [3])
        """,
        """
        foo(0, ↓param1: 1, ↓param2: true,
            param3: [3])
        """,
        """
        foo(
            0, ↓param1: 1,
            param2: true, ↓param3: [3]
        )
        """,
    ])
}
