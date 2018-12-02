internal struct EmptyXCTestMethodRuleExamples {
    static let nonTriggeringExamples = [
        // Valid XCTestCase class

        """
        class TotoTests: XCTestCase {
            var foobar: Foobar?

            override func setUp() {
                super.setUp()
                foobar = Foobar()
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
        }
        """,

        // Not an XCTestCase class

        """
        class Foobar {
            func setUp() {}

            func tearDown() {}

            func testFoo() {}
        }
        """,

        // Methods with parameters

        """
        class TotoTests: XCTestCase {
            func setUp(with object: Foobar) {}

            func tearDown(object: Foobar) {}

            func testFoo(_ foo: Foobar) {}

            func testBar(bar: (String) -> Int) {}
        }
        """,

        // Asserts in one line

        """
        class TotoTests: XCTestCase {
            func testFoo() { XCTAssertTrue(foobar?.foo) }

            func testBar() { XCTAssertFalse(foobar?.bar) }
        }
        """
    ]

    static let triggeringExamples = [
        // XCTestCase class with empty methods

        """
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
        """,

        """
        class TotoTests: XCTestCase {
            override ↓func setUp() {}

            override ↓func tearDown() {}

            ↓func testFoo() {}

            func helperFunction() {}
        }
        """,

        // XCTestCase class with comments (and blank lines)

        """
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
        """,

        // Two XCTestCase classes on the same file

        """
        class FooTests: XCTestCase {
            override ↓func setUp() {}
        }

        class BarTests: XCTestCase {
            ↓func testFoo() {}
        }
        """
    ]
}
