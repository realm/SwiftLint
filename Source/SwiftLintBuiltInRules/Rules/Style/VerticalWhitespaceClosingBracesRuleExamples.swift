import SwiftLintCore

// swiftlint:disable:next type_name
internal struct VerticalWhitespaceClosingBracesRuleExamples {
    private static let beforeTrivialLinesConfiguration = ["only_enforce_before_trivial_lines": true]

    static let nonTriggeringExamples = #examples([
        "[1, 2].map { $0 }.filter { true }",
        "[1, 2].map { $0 }.filter { num in true }",
        """
        /*
            class X {

                let x = 5

            }
        */
        """,
        """
        if bool1 {
          // do something
          // do something

        } else if bool2 {
          // do something
          // do something
          // do something

        } else {
          // do something
          // do something
        }
        """.configuration(beforeTrivialLinesConfiguration).excludeFromDocumentation(),
    ])

    static let violatingToValidExamples = #corrections([
        """
        do {
          print("x is 5")
        ↓
        }
        """:
            """
            do {
              print("x is 5")
            }
            """,
        """
        do {
          print("x is 5")
        ↓

        }
        """:
            """
            do {
              print("x is 5")
            }
            """,
        """
        do {
          print("x is 5")
        ↓\n  \n}
        """:
            """
            do {
              print("x is 5")
            }
            """,
        """
        [
        1,
        2,
        3
        ↓
        ]
        """:
            """
            [
            1,
            2,
            3
            ]
            """,
        """
        foo(
            x: 5,
            y:6
        ↓
        )
        """:
            """
            foo(
                x: 5,
                y:6
            )
            """,
        """
        func foo() {
          run(5) { x in
            print(x)
          }
        ↓
        }
        """: """
            func foo() {
              run(5) { x in
                print(x)
              }
            }
            """,
        """
        print([
          1
        ↓
        ])
        """.configuration(beforeTrivialLinesConfiguration):
            """
                    print([
                      1
                    ])
                    """.configuration(beforeTrivialLinesConfiguration),
        """
        print([foo {
          var sum = 0
          for i in 1...5 { sum += i }
          return sum

        }, foo {
          var mul = 1
          for i in 1...5 { mul *= i }
          return mul
        ↓
        }])
        """.configuration(beforeTrivialLinesConfiguration):
            """
            print([foo {
              var sum = 0
              for i in 1...5 { sum += i }
              return sum

            }, foo {
              var mul = 1
              for i in 1...5 { mul *= i }
              return mul
            }])
            """.configuration(beforeTrivialLinesConfiguration),
    ])
}
