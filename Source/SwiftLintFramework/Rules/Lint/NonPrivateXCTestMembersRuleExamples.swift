internal struct NonPrivateXCTestMembersRuleExamples {
    static let nonTriggeringExamples = [
        // Valid XCTestCase class

        Example("""
        class TotoTests: XCTestCase {
            private var foo: Bar?
            fileprivate func baz() {}

            override class func setUp() {}
            override static func tearDown() {}

            override func setUp() {
                super.setUp()
            }

            override func tearDown() {}

            func testFoo() {}

            func testBar() {}
        }
        """),

        // Not an XCTestCase class

        Example("""
        class Foobar {
            var foo: Bar?

            func setUp() {}

            func tearDown() {}

            func testFoo() {}
        }
        """)
    ]

    static let triggeringExamples = [
        Example("""
        class TotoTests: XCTestCase {
            ↓var foo: Bar?

            ↓struct Baz {}

            override func setUp() {}

            override func tearDown() {}

            func testFoo() {}

            func testBar() {}

            ↓func helperFunction() {}
        }
        """)
    ]
}
