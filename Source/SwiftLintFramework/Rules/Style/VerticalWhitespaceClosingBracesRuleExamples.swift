// swiftlint:disable:next type_name
internal struct VerticalWhitespaceClosingBracesRuleExamples {
    private static let beforeTrivialLinesConfiguration = ["only_enforce_before_trivial_lines": true]

    static let nonTriggeringExamples = [
        Example("[1, 2].map { $0 }.filter { true }"),
        Example("[1, 2].map { $0 }.filter { num in true }"),
        Example("""
        /*
            class X {

                let x = 5

            }
        */
        """),
        Example("""
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
        """, configuration: beforeTrivialLinesConfiguration)
    ]

    static let violatingToValidExamples = [
        Example("""
        do {
          print("x is 5")
        ↓
        }
        """):
            Example("""
            do {
              print("x is 5")
            }
            """),
        Example("""
        do {
          print("x is 5")
        ↓

        }
        """):
            Example("""
            do {
              print("x is 5")
            }
            """),
        Example("""
        do {
          print("x is 5")
        ↓\n  \n}
        """):
            Example("""
            do {
              print("x is 5")
            }
            """),
        Example("""
        [
        1,
        2,
        3
        ↓
        ]
        """):
            Example("""
            [
            1,
            2,
            3
            ]
            """),
        Example("""
        foo(
            x: 5,
            y:6
        ↓
        )
        """):
            Example("""
            foo(
                x: 5,
                y:6
            )
            """),
        Example("""
        func foo() {
          run(5) { x in
            print(x)
          }
        ↓
        }
        """): Example("""
            func foo() {
              run(5) { x in
                print(x)
              }
            }
            """),
        Example("""
        print([
          1
        ↓
        ])
        """, configuration: beforeTrivialLinesConfiguration):
            Example("""
                    print([
                      1
                    ])
                    """, configuration: beforeTrivialLinesConfiguration),
        Example("""
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
        """, configuration: beforeTrivialLinesConfiguration):
            Example("""
            print([foo {
              var sum = 0
              for i in 1...5 { sum += i }
              return sum

            }, foo {
              var mul = 1
              for i in 1...5 { mul *= i }
              return mul
            }])
            """, configuration: beforeTrivialLinesConfiguration)
    ]
}
