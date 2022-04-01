@testable import SwiftLintFramework
import XCTest

class RuleConfigurationDescriptionTests: XCTestCase {
    func testEmptyDescription() {
        let description = description { RuleConfigurationOption.noOptions }

        XCTAssertTrue(description.oneLiner().isEmpty)
        XCTAssertTrue(description.markdown().isEmpty)
    }

    // swiftlint:disable:next function_body_length
    func testBasicTypes() {
        let description = description {
            "flag" => .flag(true)
            "string" => .string("value")
            "symbol" => .symbol("value")
            "integer" => .integer(-12)
            "float" => .float(42.0)
            "severity" => .severity(.error)
            "list" => .list([.symbol("value"), .string("value"), .float(12.8)])
        }

        XCTAssertEqual(description.markdown(), """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            flag
            </td>
            <td>
            true
            </td>
            </tr>
            <tr>
            <td>
            string
            </td>
            <td>
            &quot;value&quot;
            </td>
            </tr>
            <tr>
            <td>
            symbol
            </td>
            <td>
            value
            </td>
            </tr>
            <tr>
            <td>
            integer
            </td>
            <td>
            -12
            </td>
            </tr>
            <tr>
            <td>
            float
            </td>
            <td>
            42.0
            </td>
            </tr>
            <tr>
            <td>
            severity
            </td>
            <td>
            error
            </td>
            </tr>
            <tr>
            <td>
            list
            </td>
            <td>
            [value, &quot;value&quot;, 12.8]
            </td>
            </tr>
            </tbody>
            </table>
            """)

        XCTAssertEqual(description.oneLiner(), """
            flag: true; string: "value"; symbol: value; integer: -12; float: 42.0; \
            severity: error; list: [value, "value", 12.8]
            """)
    }

    // swiftlint:disable:next function_body_length
    func testNestedDescription() {
        let description = description {
            "flag" => .flag(true)
            "nested 1" => .nest {
                "integer" => .integer(2)
                "nested 2" => .nest {
                    "float" => .float(42.1)
                }
                "symbol" => .symbol("value")
            }
            "string" => .string("value")
        }

        XCTAssertEqual(description.markdown(), """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            flag
            </td>
            <td>
            true
            </td>
            </tr>
            <tr>
            <td>
            nested 1
            </td>
            <td>
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            integer
            </td>
            <td>
            2
            </td>
            </tr>
            <tr>
            <td>
            nested 2
            </td>
            <td>
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            float
            </td>
            <td>
            42.1
            </td>
            </tr>
            </tbody>
            </table>
            </td>
            </tr>
            <tr>
            <td>
            symbol
            </td>
            <td>
            value
            </td>
            </tr>
            </tbody>
            </table>
            </td>
            </tr>
            <tr>
            <td>
            string
            </td>
            <td>
            &quot;value&quot;
            </td>
            </tr>
            </tbody>
            </table>
            """)

        XCTAssertEqual(description.oneLiner(), """
            flag: true; nested 1: integer: 2; nested 2: float: 42.1; symbol: value; string: "value"
            """)
    }

    private func description(@RuleConfigurationDescriptionBuilder _ content: () -> RuleConfigurationDescription)
        -> RuleConfigurationDescription { content() }
}
