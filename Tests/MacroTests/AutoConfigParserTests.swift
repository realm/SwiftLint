import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import SwiftLintCoreMacros

private let macros = [
    "AutoConfigParser": MacroSpec(type: AutoConfigParser.self)
]

@Suite
struct AutoConfigParserTests {
    @Test
    func attachToClass() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            class C {
            }
            """,
            expandedSource:
            """
            class C {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: SwiftLintCoreMacroError.notStruct.message, line: 1, column: 1)
            ],
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func noConfigurationElements() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct MyConfiguration {
            }
            """,
            expandedSource:
            """
            struct MyConfiguration {

                typealias Parent = MyRule

                mutating func apply(configuration: Any) throws(SwiftLintCore.Issue) {
                    guard let configuration = configuration as? [String: Any] else {
                        throw .invalidConfiguration(ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        SwiftLintCore.Issue.invalidConfigurationKeys(
                            ruleID: Parent.identifier,
                            keys: unknownKeys
                        ).print()
                    }
                    try validate()
                }
            }
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func configurationElementsWithoutKeys() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct MyConfiguration {
                @ConfigurationElement
                var eA = 1
                @ConfigurationElement(key: "name")
                var eB = 2
            }
            """,
            expandedSource:
            """
            struct MyConfiguration {
                @ConfigurationElement
                var eA = 1
                @ConfigurationElement(key: "name")
                var eB = 2

                typealias Parent = MyRule

                mutating func apply(configuration: Any) throws(SwiftLintCore.Issue) {
                    if $eA.key.isEmpty {
                        $eA.key = "e_a"
                    }
                    if $eB.key.isEmpty {
                        $eB.key = "e_b"
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        throw .invalidConfiguration(ruleID: Parent.identifier)
                    }
                    if let value = configuration[$eA.key] {
                        try eA.apply(value, ruleID: Parent.identifier)
                    }
                    if let value = configuration[$eB.key] {
                        try eB.apply(value, ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        SwiftLintCore.Issue.invalidConfigurationKeys(
                            ruleID: Parent.identifier,
                            keys: unknownKeys
                        ).print()
                    }
                    try validate()
                }
            }
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func inlinedConfigurationElements() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct MyConfiguration {
                @ConfigurationElement(key: "eD")
                var eA = 1
                @ConfigurationElement(inline: true)
                var eB = 2
                @ConfigurationElement(inline: false)
                var eC = 3
            }
            """,
            expandedSource:
            """
            struct MyConfiguration {
                @ConfigurationElement(key: "eD")
                var eA = 1
                @ConfigurationElement(inline: true)
                var eB = 2
                @ConfigurationElement(inline: false)
                var eC = 3

                typealias Parent = MyRule

                mutating func apply(configuration: Any) throws(SwiftLintCore.Issue) {
                    if $eA.key.isEmpty {
                        $eA.key = "e_a"
                    }
                    if $eC.key.isEmpty {
                        $eC.key = "e_c"
                    }
                    do {
                        try eB.apply(configuration, ruleID: Parent.identifier)
                    } catch let issue where issue == SwiftLintCore.Issue.nothingApplied(ruleID: Parent.identifier) {
                        // Acceptable. Continue.
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        return
                    }
                    if let value = configuration[$eA.key] {
                        try eA.apply(value, ruleID: Parent.identifier)
                    }
                    if let value = configuration[$eC.key] {
                        try eC.apply(value, ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        SwiftLintCore.Issue.invalidConfigurationKeys(
                            ruleID: Parent.identifier,
                            keys: unknownKeys
                        ).print()
                    }
                    try validate()
                }
            }
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance        )
    }

    @Test
    func severityBasedConfigurationWithoutSeverityProperty() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct MyConfiguration: SeverityBasedRuleConfiguration {
            }
            """,
            expandedSource:
            """
            struct MyConfiguration: SeverityBasedRuleConfiguration {

                typealias Parent = MyRule

                mutating func apply(configuration: Any) throws(SwiftLintCore.Issue) {
                    guard let configuration = configuration as? [String: Any] else {
                        throw .invalidConfiguration(ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        SwiftLintCore.Issue.invalidConfigurationKeys(
                            ruleID: Parent.identifier,
                            keys: unknownKeys
                        ).print()
                    }
                    try validate()
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: SwiftLintCoreMacroError.severityBasedWithoutProperty.message,
                    line: 2,
                    column: 8
                ),
            ],
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func severityAppliedTwice() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct MyConfiguration: SeverityBasedRuleConfiguration {
                @ConfigurationElement
                var severityConfiguration = .warning
                @ConfigurationElement
                var foo = 2
            }
            """,
            expandedSource:
            """
            struct MyConfiguration: SeverityBasedRuleConfiguration {
                @ConfigurationElement
                var severityConfiguration = .warning
                @ConfigurationElement
                var foo = 2

                typealias Parent = MyRule

                mutating func apply(configuration: Any) throws(SwiftLintCore.Issue) {
                    if $severityConfiguration.key.isEmpty {
                        $severityConfiguration.key = "severity_configuration"
                    }
                    if $foo.key.isEmpty {
                        $foo.key = "foo"
                    }
                    do {
                        try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
                    } catch let issue where issue == SwiftLintCore.Issue.nothingApplied(ruleID: Parent.identifier) {
                        // Acceptable. Continue.
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        return
                    }
                    if let value = configuration[$severityConfiguration.key] {
                        try severityConfiguration.apply(value, ruleID: Parent.identifier)
                    }
                    if let value = configuration[$foo.key] {
                        try foo.apply(value, ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        SwiftLintCore.Issue.invalidConfigurationKeys(
                            ruleID: Parent.identifier,
                            keys: unknownKeys
                        ).print()
                    }
                    try validate()
                }
            }
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }
}
