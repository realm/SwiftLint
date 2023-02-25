@testable import SwiftLintFramework
import XCTest

final class ImplicitGetterRuleTests: XCTestCase {
    func testPropertyReason() async throws {
        let config = try XCTUnwrap(makeConfig(nil, ImplicitGetterRule.description.identifier))
        let example = Example("""
        class Foo {
            var foo: Int {
                ↓get {
                    return 20
                }
            }
        }
        """)

        let violations = try await violations(example, config: config)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Computed read-only properties should avoid using the get keyword")
    }

    func testSubscriptReason() async throws {
        let config = try XCTUnwrap(makeConfig(nil, ImplicitGetterRule.description.identifier))
        let example = Example("""
        class Foo {
            subscript(i: Int) -> Int {
                ↓get {
                    return 20
                }
            }
        }
        """)

        let violations = try await violations(example, config: config)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations.first?.reason, "Computed read-only subscripts should avoid using the get keyword")
    }
}
