@testable import SwiftLintCore
import TestHelpers
import XCTest

// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
final class RuleConfigurationDescriptionTests: SwiftLintTestCase {
    @AutoConfigParser
    private struct TestConfiguration: RuleConfiguration {
        typealias Parent = RuleMock // swiftlint:disable:this nesting

        @ConfigurationElement(key: "flag")
        var flag = true
        @ConfigurationElement(key: "string")
        var string = "value"
        @ConfigurationElement(key: "symbol")
        var symbol = try! Symbol(fromAny: "value", context: "rule") // swiftlint:disable:this force_try
        @ConfigurationElement(key: "integer")
        var integer = 2
        @ConfigurationElement(key: "null")
        var null: Int?
        @ConfigurationElement(key: "my_double")
        var myDouble = 2.1
        @ConfigurationElement(key: "severity")
        var severity = ViolationSeverity.warning
        @ConfigurationElement(
            key: "list",
            postprocessor: { list in list = list.map { $0.uppercased() } }
        )
        var list = ["string1", "string2"]
        @ConfigurationElement(key: "set", deprecationNotice: .suggestAlternative(ruleID: "my_rule", name: "other_opt"))
        var set: Set<Int> = [1, 2, 3]
        @ConfigurationElement(inline: true)
        var severityConfig = SeverityConfiguration<Parent>(.error)
        @ConfigurationElement(key: "SEVERITY")
        var renamedSeverityConfig = SeverityConfiguration<Parent>(.warning)
        @ConfigurationElement(inline: true)
        var inlinedSeverityLevels = SeverityLevelsConfiguration<Parent>(warning: 1, error: nil)
        @ConfigurationElement(key: "levels")
        var nestedSeverityLevels = SeverityLevelsConfiguration<Parent>(warning: 3, error: 2)

        func isEqualTo(_: some RuleConfiguration) -> Bool { false }
    }

    // swiftlint:disable:next function_body_length
    func testDescriptionFromConfiguration() throws {
        var configuration = TestConfiguration()
        try configuration.apply(configuration: Void()) // Configure to set keys.
        let description = RuleConfigurationDescription.from(configuration: configuration)

        XCTAssertEqual(description.oneLiner(), """
            flag: true; \
            string: "value"; \
            symbol: value; \
            integer: 2; \
            my_double: 2.1; \
            severity: warning; \
            list: ["STRING1", "STRING2"]; \
            set: [1, 2, 3]; \
            severity: error; \
            SEVERITY: warning; \
            warning: 1; \
            levels: warning: 3, error: 2
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
            my_double
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
            [&quot;STRING1&quot;, &quot;STRING2&quot;]
            </td>
            </tr>
            <tr>
            <td>
            set
            </td>
            <td>
            [1, 2, 3]
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
            <tr>
            <td>
            error
            </td>
            <td>
            2
            </td>
            </tr>
            </tbody>
            </table>
            </td>
            </tr>
            </tbody>
            </table>
            """)

        XCTAssertEqual(description.yaml(), """
            flag: true
            string: "value"
            symbol: value
            integer: 2
            my_double: 2.1
            severity: warning
            list: ["STRING1", "STRING2"]
            set: [1, 2, 3]
            severity: error
            SEVERITY: warning
            warning: 1
            levels:
              warning: 3
              error: 2
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

            mutating func apply(configuration _: Any) throws { /* conformance for test */ }

            func isEqualTo(_: some RuleConfiguration) -> Bool { false }
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
        XCTAssertEqual(description.yaml(), "visible: true")
    }

    func testEmptyDescription() {
        let description = description { RuleConfigurationOption.noOptions }

        XCTAssertTrue(description.oneLiner().isEmpty)
        XCTAssertTrue(description.markdown().isEmpty)
        XCTAssertTrue(description.yaml().isEmpty)
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

        XCTAssertEqual(description.yaml(), """
            flag: true
            string: "value"
            symbol: value
            integer: -12
            float: 42.0
            severity: error
            list: [value, "value", 12.8]
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
            flag: true; nested 1: integer: 2, nested 2: float: 42.1, symbol: value; string: "value"
            """)

        XCTAssertEqual(description.yaml(), """
            flag: true
            nested 1:
              integer: 2
              nested 2:
                float: 42.1
              symbol: value
            string: "value"
            """)
    }

    func testUpdate() throws {
        var configuration = TestConfiguration()

        try configuration.apply(configuration: [
            "flag": false,
            "string": "new value",
            "symbol": "new symbol",
            "integer": 5,
            "null": 0,
            "my_double": 5.1,
            "severity": "error",
            "list": ["string3", "string4"],
            "set": [4, 5, 6],
            "SEVERITY": "error",
            "warning": 12,
            "levels": ["warning": 6, "error": 7],
        ])

        XCTAssertFalse(configuration.flag)
        XCTAssertEqual(configuration.string, "new value")
        XCTAssertEqual(configuration.symbol, try Symbol(fromAny: "new symbol", context: "rule"))
        XCTAssertEqual(configuration.integer, 5)
        XCTAssertEqual(configuration.null, 0)
        XCTAssertEqual(configuration.myDouble, 5.1)
        XCTAssertEqual(configuration.severity, .error)
        XCTAssertEqual(configuration.list, ["STRING3", "STRING4"])
        XCTAssertEqual(configuration.set, [4, 5, 6])
        XCTAssertEqual(configuration.severityConfig, .error)
        XCTAssertEqual(configuration.renamedSeverityConfig, .error)
        XCTAssertEqual(configuration.inlinedSeverityLevels, SeverityLevelsConfiguration(warning: 12))
        XCTAssertEqual(configuration.nestedSeverityLevels, SeverityLevelsConfiguration(warning: 6, error: 7))
    }

    @MainActor
    func testDeprecationWarning() async throws {
        var configuration = TestConfiguration()

        try await AsyncAssertEqual(
            try await Issue.captureConsole { try configuration.apply(configuration: ["set": [6, 7]]) },
            "warning: Configuration option 'set' in 'my_rule' rule is deprecated. Use the option 'other_opt' instead."
        )
    }

    @MainActor
    func testNoDeprecationWarningIfNoDeprecatedPropertySet() async throws {
        var configuration = TestConfiguration()

        try await AsyncAssertTrue(
            try await Issue.captureConsole { try configuration.apply(configuration: ["flag": false]) }.isEmpty
        )
    }

    @MainActor
    func testInvalidKeys() async throws {
        var configuration = TestConfiguration()

        try await AsyncAssertEqual(
            try await Issue.captureConsole {
                try configuration.apply(configuration: [
                    "severity": "error",
                    "warning": 3,
                    "unknown": 1,
                    "unsupported": true,
                ])
            },
            "warning: Configuration for 'RuleMock' rule contains the invalid key(s) 'unknown', 'unsupported'."
        )
    }

    private func description(@RuleConfigurationDescriptionBuilder _ content: () -> RuleConfigurationDescription)
        -> RuleConfigurationDescription { content() }
}
