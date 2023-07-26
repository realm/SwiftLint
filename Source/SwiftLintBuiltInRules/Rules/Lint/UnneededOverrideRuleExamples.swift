struct UnneededOverrideRuleExamples {
    static let nonTriggeringExamples = [
        Example("""
        class Foo {
            override func bar() {
                super.bar()
                print("hi")
            }
        }
        """),
        Example("""
        class Foo {
            @available(*, unavailable)
            override func bar() {
                super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            override func bar() {
                super.bar()
                super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            override func bar() throws {
                // Doing a different variation of 'try' changes behavior
                try! super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            override func bar() throws {
                // Doing a different variation of 'try' changes behavior
                try? super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            override func bar() async throws {
                // Doing a different variation of 'try' changes behavior
                await try! super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            override func bar(arg: Bool) {
                // Flipping the argument changes behavior
                super.bar(arg: !arg)
            }
        }
        """),
        Example("""
        class Foo {
            override func bar(_ arg: Int) {
                // Changing the argument changes behavior
                super.bar(arg + 1)
            }
        }
        """),
        Example("""
        class Foo {
            override func bar(arg: Int) {
                // Changing the argument changes behavior
                super.bar(arg: arg.var)
            }
        }
        """),
        Example("""
        class Foo {
            override func bar(_ arg: Int) {
                // Not passing arguments because they have default values changes behavior
                super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            override func bar(arg: Int, _ arg3: Bool) {
                // Calling a super function with different argument labels changes behavior
                super.bar(arg2: arg, arg3: arg3)
            }
        }
        """),
        Example("""
        class Foo {
            override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated) {
                    // This likely changes behavior
                }
            }
        }
        """),
        Example("""
        class Foo {
            override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated, completion: {
                    // This likely changes behavior
                })
            }
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        class Foo {
            ↓override func bar() {
                super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            ↓override func bar() {
                return super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            ↓override func bar() {
                super.bar()
                // comments don't affect this
            }
        }
        """),
        Example("""
        class Foo {
            ↓override func bar() async {
                await super.bar()
            }
        }
        """),
        Example("""
        class Foo {
            ↓override func bar() throws {
                try super.bar()
                // comments don't affect this
            }
        }
        """),
        Example("""
        class Foo {
            ↓override func bar(arg: Bool) throws {
                try super.bar(arg: arg)
            }
        }
        """),
        Example("""
        class Foo {
            ↓override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated, completion: completion)
            }
        }
        """)
    ]

    static let corrections = [
        Example("""
        class Foo {
            ↓override func bar(animated: Bool, completion: () -> Void) {
                super.bar(animated: animated, completion: completion)
            }
        }
        """): Example("""
                      class Foo {
                      }
                      """),
        Example("""
        class Foo {
            ↓override func bar() {
                super.bar()
            }
        }
        """): Example("""
                      class Foo {
                      }
                      """),
        Example("""
        class Foo {
            ↓override func bar() {
                super.bar()
            }

            // This is another function
            func baz() {}
        }
        """): Example("""
                      class Foo {

                          // This is another function
                          func baz() {}
                      }
                      """)
    ]
}
