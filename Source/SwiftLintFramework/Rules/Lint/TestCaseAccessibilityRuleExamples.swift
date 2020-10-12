internal struct TestCaseAccessibilityRuleExamples {
    static let nonTriggeringExamples = [
        // Valid XCTestCase class

        Example("""
        let foo: String?

        class FooTests: XCTestCase {
            static let allTests: [String] = []

            private let foo: String {
                let nestedMember = "hi"
                return nestedMember
            }

            override static func setUp() {
                super.setUp()
            }

            override func setUp() {
                super.setUp()
            }

            override func setUpWithError() throws {
                try super.setUpWithError()
            }

            override static func tearDown() {
                super.tearDown()
            }

            override func tearDown() {
                super.tearDown()
            }

            override func tearDownWithError() {
                try super.tearDownWithError()
            }

            override func someFutureXCTestFunction() {
                super.someFutureXCTestFunction()
            }

            func testFoo() {
                XCTAssertTrue(true)
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
        """)
    ]

    static let triggeringExamples = [
        Example("""
        class FooTests: XCTestCase {
            ↓var foo: String?
            ↓let bar: String?

            ↓static func foo() {}

            ↓func setUp(withParam: String) {}

            ↓func foobar() {}

            ↓func not_testBar() {}

            ↓enum Nested {}

            ↓static func testFoo() {}

            ↓static func allTests() {}
        }

        final class BarTests: XCTestCase {
            ↓class Nested {}
        }
        """)
    ]
}
