@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let macros = [
    "AutoConfigParser": AutoConfigParser.self
]

final class AutoConfigParserTests: XCTestCase {
    func testAttachToClass() {
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
            macros: macros)
    }

    func testNoConfigurationElements() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct S {
            }
            """,
            expandedSource:
            """
            struct S {

                mutating func apply(configuration: Any) throws {
                    guard let configuration = configuration as? [String: Any] else {
                        throw Issue.invalidConfiguration(ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
                    }
                    try validate()
                }
            }
            """,
            macros: macros
        )
    }

    func testConfigurationElementsWithoutKeys() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct S {
                @ConfigurationElement
                var eA = 1
                @ConfigurationElement(key: "name")
                var eB = 2
            }
            """,
            expandedSource:
            """
            struct S {
                @ConfigurationElement
                var eA = 1
                @ConfigurationElement(key: "name")
                var eB = 2

                mutating func apply(configuration: Any) throws {
                    if $eA.key.isEmpty {
                        $eA.key = "e_a"
                    }
                    if $eB.key.isEmpty {
                        $eB.key = "e_b"
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        throw Issue.invalidConfiguration(ruleID: Parent.identifier)
                    }
                    if let value = configuration[$eA.key] {
                        try eA.apply(value, ruleID: Parent.identifier)
                    }
                    if let value = configuration[$eB.key] {
                        try eB.apply(value, ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
                    }
                    try validate()
                }
            }
            """,
            macros: macros
        )
    }

    func testInlinedConfigurationElements() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct S {
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
            struct S {
                @ConfigurationElement(key: "eD")
                var eA = 1
                @ConfigurationElement(inline: true)
                var eB = 2
                @ConfigurationElement(inline: false)
                var eC = 3

                mutating func apply(configuration: Any) throws {
                    if $eA.key.isEmpty {
                        $eA.key = "e_a"
                    }
                    if $eC.key.isEmpty {
                        $eC.key = "e_c"
                    }
                    do {
                        try eB.apply(configuration, ruleID: Parent.identifier)
                    } catch let issue as Issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
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
                        Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
                    }
                    try validate()
                }
            }
            """,
            macros: macros
        )
    }

    func testSeverityBasedConfigurationWithoutSeverityProperty() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct S: SeverityBasedRuleConfiguration {
            }
            """,
            expandedSource:
            """
            struct S: SeverityBasedRuleConfiguration {

                mutating func apply(configuration: Any) throws {
                    guard let configuration = configuration as? [String: Any] else {
                        throw Issue.invalidConfiguration(ruleID: Parent.identifier)
                    }
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
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
            macros: macros)
    }

    func testSeverityAppliedTwice() {
        assertMacroExpansion(
            """
            @AutoConfigParser
            struct S: SeverityBasedRuleConfiguration {
                @ConfigurationElement
                var severityConfiguration = .warning
                @ConfigurationElement
                var foo = 2
            }
            """,
            expandedSource:
            """
            struct S: SeverityBasedRuleConfiguration {
                @ConfigurationElement
                var severityConfiguration = .warning
                @ConfigurationElement
                var foo = 2

                mutating func apply(configuration: Any) throws {
                    if $severityConfiguration.key.isEmpty {
                        $severityConfiguration.key = "severity_configuration"
                    }
                    if $foo.key.isEmpty {
                        $foo.key = "foo"
                    }
                    do {
                        try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
                    } catch let issue as Issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
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
                        Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
                    }
                    try validate()
                }
            }
            """,
            macros: macros
        )
    }
}
