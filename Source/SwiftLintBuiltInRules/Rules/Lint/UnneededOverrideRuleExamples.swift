struct UnneededOverrideRuleExamples {
    static let nonTriggeringExamples = #examples([
        """
        class Foo {
            override func bar() {
                super.bar()
                print("hi")
            }
        }
        """,
        """
        class Foo {
            @available(*, unavailable)
            override func bar() {
                super.bar()
            }
        }
        """,
        """
        class Foo {
            @objc override func bar() {
                super.bar()
            }
        }
        """,
        """
        class Foo {
            override func bar() {
                super.bar()
                super.bar()
            }
        }
        """,
        """
        class Foo {
            override func bar() throws {
                // Doing a different variation of 'try' changes behavior
                try! super.bar()
            }
        }
        """,
        """
        class Foo {
            override func bar() throws {
                // Doing a different variation of 'try' changes behavior
                try? super.bar()
            }
        }
        """,
        """
        class Foo {
            override func bar() async throws {
                // Doing a different variation of 'try' changes behavior
                await try! super.bar()
            }
        }
        """,
        """
        class Foo {
            override func bar(arg: Bool) {
                // Flipping the argument changes behavior
                super.bar(arg: !arg)
            }
        }
        """,
        """
        class Foo {
            override func bar(_ arg: Int) {
                // Changing the argument changes behavior
                super.bar(arg + 1)
            }
        }
        """,
        """
        class Foo {
            override func bar(arg: Int) {
                // Changing the argument changes behavior
                super.bar(arg: arg.var)
            }
        }
        """,
        """
        class Foo {
            override func bar(_ arg: Int) {
                // Not passing arguments because they have default values changes behavior
                super.bar()
            }
        }
        """,
        """
        class Foo {
            override func bar(arg: Int, _ arg3: Bool) {
                // Calling a super function with different argument labels changes behavior
                super.bar(arg2: arg, arg3: arg3)
            }
        }
        """,
        """
        class Foo {
            override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated) {
                    // This likely changes behavior
                }
            }
        }
        """,
        """
        class Foo {
            override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated, completion: {
                    // This likely changes behavior
                })
            }
        }
        """,
        """
        class Baz: Foo {
            // A default argument might be a change
            override func bar(value: String = "Hello") {
                super.bar(value: value)
            }
        }
        """,
        """
        class C {
            override func foo() {
                super.foo {}
            }
            override func bar(_ c: () -> Void) {
                super.bar {}
            }
            override func baz(_ c: () -> Void) {
                super.baz({})
            }
            override func qux(c: () -> Void) {
                super.qux(c: {})
            }
        }
        """,
        """
        class FooTestCase: XCTestCase {
            override func setUp() {
                super.setUp()
            }
        }
        """.configuration(["excluded_methods": ["setUp"]]),
    ])

    static let triggeringExamples = #examples([
        """
        class Foo {
            ↓override func bar() {
                super.bar()
            }
        }
        """,
        """
        class Foo {
            ↓override func bar() {
                return super.bar()
            }
        }
        """,
        """
        class Foo {
            ↓override func bar() {
                super.bar()
                // comments don't affect this
            }
        }
        """,
        """
        class Foo {
            ↓override func bar() async {
                await super.bar()
            }
        }
        """,
        """
        class Foo {
            ↓override func bar() throws {
                try super.bar()
                // comments don't affect this
            }
        }
        """,
        """
        class Foo {
            ↓override func bar(arg: Bool) throws {
                try super.bar(arg: arg)
            }
        }
        """,
        """
        class Foo {
            ↓override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated, completion: completion)
            }
        }
        """,
    ])

    static let corrections = #corrections([
        """
        class Foo {
            ↓override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated, completion: completion)
            }
        }
        """: """
                      class Foo {
                      }
                      """,
        """
        class Foo {
            ↓override func bar() {
                super.bar()
            }
        }
        """: """
                      class Foo {
                      }
                      """,
        """
        class Foo {
            ↓override func bar() {
                super.bar()
            }

            // This is another function
            func baz() {}
        }
        """: """
                      class Foo {

                          // This is another function
                          func baz() {}
                      }
                      """,
        // Nothing happens to initializers by default.
        """
        class Foo {
            ↓override func foo() { super.foo() }
            override init(i: Int) {
                super.init(i: i)
            }
        }
        """: """
                      class Foo {
                          override init(i: Int) {
                              super.init(i: i)
                          }
                      }
                      """,
    ])
}
