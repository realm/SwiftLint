internal struct EmptyXCTestMethodRuleExamples {
    static let nonTriggeringExamples = [
        // Valid XCTestCase class

        Example("""
        class TotoTests: XCTestCase {
            var foobar: Foobar?

            override func setUp() {
                super.setUp()
                foobar = Foobar()
            }

            override func setUpWithError() throws {
                foobar = nil
            }

            override func tearDown() {
                foobar = nil
                super.tearDown()
            }

            func testFoo() {
                XCTAssertTrue(foobar?.foo)
            }

            func testBar() {
                // comment...

                XCTAssertFalse(foobar?.bar)

                // comment...
            }

            func testBaz() {
                _ = 4 + 4
            }
        }
        """),

        // Not an XCTestCase class

        Example("""
        class Foobar {
            func setUp() {}

            func tearDown() {}

            func testFoo() {}
        }
        """),

        // Methods with parameters

        Example("""
        class TotoTests: XCTestCase {
            func setUp(with object: Foobar) {}

            func tearDown(object: Foobar) {}

            func testFoo(_ foo: Foobar) {}

            func testBar(bar: (String) -> Int) {}
        }
        """),

        // Asserts in one line

        Example("""
        class TotoTests: XCTestCase {
            func testFoo() { XCTAssertTrue(foobar?.foo) }

            func testBar() { XCTAssertFalse(foobar?.bar) }
        }
        """),

        // Class/static variables

        Example("""
        class TotoTests: XCTestCase {
            override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

            static var allTests = [("testFoo", testFoo)]

            func testFoo() { XCTAssert(true) }
        }
        """),

        Example("""
        extension C {
            override func foo(a: Int) {}
        }

        struct S {
            override func foo(a: Int) {}
        }

        enum E {
            override func foo(a: Int) {}
        }
        """, excludeFromDocumentation: true)
    ]

    static let triggeringExamples = [
        // XCTestCase class with empty methods

        Example("""
        class TotoTests: XCTestCase {
            override ↓func setUp() {
            }

            override ↓func tearDown() {

            }

            ↓func testFoo() {


            }

            ↓func testBar() {



            }

            func helperFunction() {
            }
        }
        """),

        Example("""
        class TotoTests: XCTestCase {
            override ↓func setUp() {}

            override ↓func tearDown() {}

            ↓func testFoo() {}

            func helperFunction() {}
        }
        """),

        // XCTestCase class with comments (and blank lines)

        Example("""
        class TotoTests: XCTestCase {
            override ↓func setUp() {
                // comment...
            }

            override ↓func tearDown() {
                // comment...
                // comment...
            }

            ↓func testFoo() {
                // comment...

                // comment...

                // comment...
            }

            ↓func testBar() {
                /*
                 * comment...
                 *
                 * comment...
                 *
                 * comment...
                 */
            }

            func helperFunction() {
            }
        }
        """),

        // Two XCTestCase classes on the same file

        Example("""
        class FooTests: XCTestCase {
            override ↓func setUp() {}
        }

        class BarTests: XCTestCase {
            ↓func testFoo() {}
        }
        """)
    ]
}
