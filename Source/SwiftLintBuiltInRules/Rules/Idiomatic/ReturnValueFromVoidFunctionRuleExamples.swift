internal struct ReturnValueFromVoidFunctionRuleExamples {
    static let nonTriggeringExamples = #examples([
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
        func baz() {
            enum Foo {
                case bar

                init?(arg: String?) {
                    return nil
                }
            }
        }
        """.excludeFromDocumentation(),
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
        """,
        "func f() -> () { g() }",
        "func f() { g() }",
        "func f() { { return g() }() }",
        """
        func f() {
            func g() -> Int {
                return 1
            }
        }
        """,
        "init?() { return nil }",
        """
        func f() {
            var i: Int { return 1 }
        }
        """,
        #"""
        final class SearchMessagesDataSource: ValueCellDataSource {
          internal enum Section: Int {
            case emptyState
            case messageThreads
          }

          internal func load(messageThreads: [MessageThread]) {
            self.set(
              values: messageThreads,
              cellClass: MessageThreadCell.self,
              inSection: Section.messageThreads.rawValue
            )
          }

          internal func emptyState(isVisible: Bool) {
            self.set(
              cellIdentifiers: isVisible ? ["SearchMessagesEmptyState"] : [],
              inSection: Section.emptyState.rawValue
            )
          }

          internal override func configureCell(tableCell cell: UITableViewCell, withValue value: Any) {
            switch (cell, value) {
            case let (cell as MessageThreadCell, value as MessageThread):
              cell.configureWith(value: value)
            case (is StaticTableViewCell, is Void):
              return
            default:
              assertionFailure("Unrecognized combo: \(cell), \(value).")
            }
          }
        }
        """#.excludeFromDocumentation(),
    ])

    static let triggeringExamples = #examples([
        """
        func foo() {
            ↓return bar()
        }
        """,
        """
        func foo() -> () {
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
        """,
    ])

    static let corrections = #corrections([
        """
        func f() -> Void {
            ↓return g()
            // some comment
        }
        """: """
            func f() -> Void {
                g()
                return
                // some comment
            }
            """,
        """
        func f(b: Bool) {
            if b {
                // some comment
                ↓return g()
            }
        }
        """: """
            func f(b: Bool) {
                if b {
                    // some comment
                    g()
                    return
                }
            }
            """,
    ])
}
