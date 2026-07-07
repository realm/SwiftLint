import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ImplicitGetterRuleTests {
    @Test
    func propertyReason() throws {
        let config = try #require(makeConfig(nil, ImplicitGetterRule.identifier))
        let example = Example("""
            class Foo {
                var foo: Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """)

        let violations = violations(example, config: config)
        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Computed read-only properties should avoid using the get keyword")
    }

    @Test
    func subscriptReason() throws {
        let config = try #require(makeConfig(nil, ImplicitGetterRule.identifier))
        let example = Example("""
            class Foo {
                subscript(i: Int) -> Int {
                    ↓get {
                        return 20
                    }
                }
            }
            """)

        let violations = violations(example, config: config)
        #expect(violations.count == 1)
        #expect(violations.first?.reason == "Computed read-only subscripts should avoid using the get keyword")
    }
}
