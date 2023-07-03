@testable import SwiftLintCore
import XCTest

// swiftlint:disable file_length

class RuleConfigurationDescriptionTests: XCTestCase {
    private struct TestConfiguration: RuleConfiguration {
        typealias Parent = RuleMock // swiftlint:disable:this nesting

        @ConfigurationElement(key: "flag")
        var flag = true
        @ConfigurationElement(key: "string")
        var string = "value"
        @ConfigurationElement(key: "symbol")
        var symbol = Symbol(value: "value")
        @ConfigurationElement(key: "integer")
        var integer = 2
        @ConfigurationElement(key: "nil")
        var `nil`: Int?
        @ConfigurationElement(key: "double")
        var double = 2.1
        @ConfigurationElement(key: "severity")
        var severity = ViolationSeverity.warning
        @ConfigurationElement(key: "list")
        var list: [OptionType?] = [.flag(true), .string("value")]
        @ConfigurationElement
        var severityConfig = SeverityConfiguration<Parent>(.error)
        @ConfigurationElement(key: "SEVERITY")
        var renamedSeverityConfig = SeverityConfiguration<Parent>(.warning)
        @ConfigurationElement
        var inlinedSeverityLevels = SeverityLevelsConfiguration<Parent>(warning: 1, error: 2)
        @ConfigurationElement(key: "levels")
        var nestedSeverityLevels = SeverityLevelsConfiguration<Parent>(warning: 3, error: nil)

        mutating func apply(configuration: Any) throws {}

        func isEqualTo(_ ruleConfiguration: some RuleConfiguration) -> Bool { false }
    }

    // swiftlint:disable:next function_body_length
    func testDescriptionFromConfiguration() {
        let description = RuleConfigurationDescription.from(configuration: TestConfiguration())

        XCTAssertEqual(description.oneLiner(), """
            flag: true; \
            string: "value"; \
            symbol: value; \
            integer: 2; \
            double: 2.1; \
            severity: warning; \
            list: [true, "value"]; \
            severity: error; \
            SEVERITY: warning; \
            warning: 1; \
            error: 2; \
            levels: warning: 3
            """)

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
            2
            </td>
            </tr>
            <tr>
            <td>
            double
            </td>
            <td>
            2.1
            </td>
            </tr>
            <tr>
            <td>
            severity
            </td>
            <td>
            warning
            </td>
            </tr>
            <tr>
            <td>
            list
            </td>
            <td>
            [true, &quot;value&quot;]
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
            SEVERITY
            </td>
            <td>
            warning
            </td>
            </tr>
            <tr>
            <td>
            warning
            </td>
            <td>
            1
            </td>
            </tr>
            <tr>
            <td>
            error
            </td>
            <td>
            2
            </td>
            </tr>
            <tr>
            <td>
            levels
            </td>
            <td>
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            warning
            </td>
            <td>
            3
            </td>
            </tr>
            </tbody>
            </table>
            </td>
            </tr>
            </tbody>
            </table>
            """)
    }

    func testPrefersParameterDescription() {
        struct Config: RuleConfiguration {
            typealias Parent = RuleMock // swiftlint:disable:this nesting

            var parameterDescription: RuleConfigurationDescription? {
                "visible" => .flag(true)
            }

            @ConfigurationElement(key: "invisible")
            var invisible = true

            mutating func apply(configuration: Any) throws {}

            func isEqualTo(_ ruleConfiguration: some RuleConfiguration) -> Bool { false }
        }

        let description = RuleConfigurationDescription.from(configuration: Config())
        XCTAssertEqual(description.oneLiner(), "visible: true")
        XCTAssertEqual(description.markdown(), """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            <tr>
            <td>
            visible
            </td>
            <td>
            true
            </td>
            </tr>
            </tbody>
            </table>
            """)
    }

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
