internal struct ReturnValueFromVoidFunctionRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        func foo() {
            return
        }
        """),
        Example("""
        func foo() {
            return /* a comment */
        }
        """),
        Example("""
        func foo() -> Int {
            return 1
        }
        """),
        Example("""
        func foo() -> Void {
            if condition {
                return
            }
            bar()
        }
        """),
        Example("""
        func foo() {
            return;
            bar()
        }
        """),
        Example("func test() {}"),
        Example("""
        init?() {
            guard condition else {
                return nil
            }
        }
        """),
        Example("""
        init?(arg: String?) {
            guard arg != nil else {
                return nil
            }
        }
        """),
        Example("""
        func test() {
            guard condition else {
                return
            }
        }
        """),
        Example("""
        func test() -> Result<String, Error> {
            func other() {}
            func otherVoid() -> Void {}
        }
        """),
        Example("""
        func test() -> Int? {
            return nil
        }
        """),
        Example("""
        func test() {
            if bar {
                print("")
                return
            }
            let foo = [1, 2, 3].filter { return true }
            return
        }
        """),
        Example("""
        func test() {
            guard foo else {
                bar()
                return
            }
        }
        """),
        Example("""
        func spec() {
            var foo: Int {
                return 0
            }
        """),
        Example(#"""
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
        """#, excludeFromDocumentation: true)
    ]

    static let triggeringExamples = [
        Example("""
        func foo() {
            ↓return bar()
        }
        """),
        Example("""
        func foo() {
            ↓return self.bar()
        }
        """),
        Example("""
        func foo() -> Void {
            ↓return bar()
        }
        """),
        Example("""
        func foo() -> Void {
            ↓return /* comment */ bar()
        }
        """),
        Example("""
        func foo() {
            ↓return
            self.bar()
        }
        """),
        Example("""
        func foo() {
            variable += 1
            ↓return
            variable += 1
        }
        """),
        Example("""
        func initThing() {
            guard foo else {
                ↓return print("")
            }
        }
        """),
        Example("""
        // Leading comment
        func test() {
            guard condition else {
                ↓return assertionfailure("")
            }
        }
        """),
        Example("""
        func test() -> Result<String, Error> {
            func other() {
                guard false else {
                    ↓return assertionfailure("")
                }
            }
            func otherVoid() -> Void {}
        }
        """),
        Example("""
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
        """),
        Example("""
        func test() {
            guard otherCondition else {
                ↓return assertionfailure(""); // comment
            }
            differentSideEffect()
        }
        """),
        Example("""
        func test() {
          if x {
            ↓return foo()
          }
          bar()
        }
        """),
        Example("""
        func test() {
          switch x {
            case .a:
              ↓return foo() // return to skip baz()
            case .b:
              bar()
          }
          baz()
        }
        """),
        Example("""
        func test() {
          if check {
            if otherCheck {
              ↓return foo()
            }
          }
          bar()
        }
        """),
        Example("""
        func test() {
            ↓return foo()
        }
        """),
        Example("""
        func test() {
          ↓return foo({
            return bar()
          })
        }
        """),
        Example("""
        func test() {
          guard x else {
            ↓return foo()
          }
          bar()
        }
        """),
        Example("""
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
        """)
    ]
}
