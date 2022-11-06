internal struct TestCaseAccessibilityRuleExamples {
    static let nonTriggeringExamples = [
        // Valid XCTestCase class

        Example("let foo: String?"),
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

            func testBar() {
                func nestedFunc() {}
            }

            private someFunc(hasParam: Bool) {}
        }
        """),

        Example("""
        class FooTests: XCTestCase {
            private struct MockSomething: Something {}
        }
        """),

        Example("""
        class FooTests: XCTestCase {
            func allowedPrefixTestFoo() {}
        }
        """, configuration: ["allowed_prefixes": ["allowedPrefix"]]),

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
            ↓typealias Bar = Foo.Bar

            ↓var foo: String?
            ↓let bar: String?

            ↓static func foo() {}

            ↓func setUp(withParam: String) {}

            ↓func foobar() {}

            ↓func not_testBar() {}

            ↓enum Nested {}

            ↓static func testFoo() {}

            ↓static func allTests() {}

            ↓func testFoo(hasParam: Bool) {}
        }

        final class BarTests: XCTestCase {
            ↓class Nested {}
        }
        """)
    ]

    static let corrections = [
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
        """):
        Example("""
        class TotoTests: XCTestCase {
            private var foo: Bar?

            private struct Baz {}

            override func setUp() {}

            override func tearDown() {}

            func testFoo() {}

            func testBar() {}

            private func helperFunction() {}
        }
        """)
    ]
}
