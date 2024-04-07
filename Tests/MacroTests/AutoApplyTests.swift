@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let macros = [
    "AutoApply": AutoApply.self
]

final class AutoApplyTests: XCTestCase {
    func testAttachToClass() {
        assertMacroExpansion(
            """
            @AutoApply
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
            @AutoApply
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
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testConfigurationElementsWithoutKeys() {
        assertMacroExpansion(
            """
            @AutoApply
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
                    try eA.apply(configuration[$eA.key], ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    try eB.apply(configuration[$eB.key], ruleID: Parent.identifier)
                    try $eB.performAfterParseOperations()
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testInlinedConfigurationElements() {
        assertMacroExpansion(
            """
            @AutoApply
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
                        try $eB.performAfterParseOperations()
                    } catch let issue as Issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
                        // Acceptable. Continue.
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        return
                    }
                    try eA.apply(configuration[$eA.key], ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    try eC.apply(configuration[$eC.key], ruleID: Parent.identifier)
                    try $eC.performAfterParseOperations()
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testSeverityBasedConfigurationWithoutSeverityProperty() {
        assertMacroExpansion(
            """
            @AutoApply
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
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: SwiftLintCoreMacroError.severityBasedWithoutProperty.message,
                    line: 2,
                    column: 8
                )
            ],
            macros: macros)
    }

    func testSeverityAppliedTwice() {
        assertMacroExpansion(
            """
            @AutoApply
            struct S: SeverityBasedRuleConfiguration {
                @ConfigurationElement
                var severity = .warning
                @ConfigurationElement
                var foo = 2
            }
            """,
            expandedSource:
            """
            struct S: SeverityBasedRuleConfiguration {
                @ConfigurationElement
                var severity = .warning
                @ConfigurationElement
                var foo = 2

                mutating func apply(configuration: Any) throws {
                    if $severity.key.isEmpty {
                        $severity.key = "severity"
                    }
                    if $foo.key.isEmpty {
                        $foo.key = "foo"
                    }
                    do {
                        try severity.apply(configuration, ruleID: Parent.identifier)
                        try $severity.performAfterParseOperations()
                    } catch let issue as Issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
                        // Acceptable. Continue.
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        return
                    }
                    try severity.apply(configuration[$severity.key], ruleID: Parent.identifier)
                    try $severity.performAfterParseOperations()
                    try foo.apply(configuration[$foo.key], ruleID: Parent.identifier)
                    try $foo.performAfterParseOperations()
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            macros: macros
        )
    }
}
