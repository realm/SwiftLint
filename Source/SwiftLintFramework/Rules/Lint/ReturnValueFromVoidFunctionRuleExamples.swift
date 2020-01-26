// swiftlint:disable:next type_body_length
internal struct ReturnValueFromVoidFunctionRuleExamples {
    static let nonTriggeringExamples = [
        """
        func foo() {
            return
        }
        """,
        """
        func foo() {
            return /* a comment */
        }
        """,
        """
        func foo() -> Int {
            return 1
        }
        """,
        """
        func foo() -> Void {
            if condition {
                return
            }
            bar()
        }
        """,
        """
        func foo() {
            return;
            bar()
        }
        """,
        "",
        "func test() {}",
        """
        init?() {
            guard condition else {
                return nil
            }
        }
        """,
        """
        init?(arg: String?) {
            guard arg != nil else {
                return nil
            }
        }
        """,
        """
        func test() {
            guard condition else {
                return
            }
        }
        """,
        """
        func test() -> Result<String, Error> {
            func other() {}
            func otherVoid() -> Void {}
        }
        """,
        """
        func test() -> Int? {
            return nil
        }
        """,
        """
        func test() {
            if bar {
                print("")
                return
            }
            let foo = [1, 2, 3].filter { return true }
            return
        }
        """,
        """
        func test() {
            guard foo else {
                bar()
                return
            }
        }
        """,
        """
        func spec() {
            var foo: Int {
                return 0
            }
        """
    ]

    static let triggeringExamples = [
        """
        func foo() {
            ↓return bar()
        }
        """,
        """
        func foo() {
            ↓return self.bar()
        }
        """,
        """
        func foo() -> Void {
            ↓return bar()
        }
        """,
        """
        func foo() -> Void {
            ↓return /* comment */ bar()
        }
        """,
        """
        func foo() {
            ↓return
            self.bar()
        }
        """,
        """
        func foo() {
            variable += 1
            ↓return
            variable += 1
        }
        """,
        """
        func initThing() {
            guard foo else {
                ↓return print("")
            }
        }
        """,
        """
        // Leading comment
        func test() {
            guard condition else {
                ↓return assertionfailure("")
            }
        }
        """,
        """
        func test() -> Result<String, Error> {
            func other() {
                guard false else {
                    ↓return assertionfailure("")
                }
            }
            func otherVoid() -> Void {}
        }
        """,
        """
        func test() {
            guard conditionIsTrue else {
                sideEffects()
                return // comment
            }
            guard otherCondition else {
                ↓return assertionfailure("")
            }
            differentSideEffect()
        }
        """,
        """
        func test() {
            guard otherCondition else {
                ↓return assertionfailure(""); // comment
            }
            differentSideEffect()
        }
        """,
        """
        func test() {
          if x {
            ↓return foo()
          }
          bar()
        }
        """,
        """
        func test() {
          switch x {
            case .a:
              ↓return foo() // return to skip baz()
            case .b:
              bar()
          }
          baz()
        }
        """,
        """
        func test() {
          if check {
            if otherCheck {
              ↓return foo()
            }
          }
          bar()
        }
        """,
        """
        func test() {
            ↓return foo()
        }
        """,
        """
        func test() {
          ↓return foo({
            return bar()
          })
        }
        """,
        """
        func test() {
          guard x else {
            ↓return foo()
          }
          bar()
        }
        """,
        """
        func test() {
          let closure: () -> () = {
            return assert()
          }
          if check {
            if otherCheck {
              return // comments are fine
            }
          }
          ↓return foo()
        }
        """
    ]
}
