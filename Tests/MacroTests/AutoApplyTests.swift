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
                    var inlinableOptionsExist = false

                    guard let configuration = configuration as? [String: Any] else {
                        if inlinableOptionsExist {
                            return
                        } else {
                            throw Issue.invalidConfiguration(ruleID: Parent.description.identifier)
                        }
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
                @ConfigurationElement(value: 7)
                var eB = 2
            }
            """,
            expandedSource:
            """
            struct S {
                @ConfigurationElement
                var eA = 1
                @ConfigurationElement(value: 7)
                var eB = 2

                mutating func apply(configuration: Any) throws {
                    var inlinableOptionsExist = false
                    if $eA.inlinable {
                    inlinableOptionsExist = true
                    try eA.apply(configuration, ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    }
                    if $eB.inlinable {
                        inlinableOptionsExist = true
                        try eB.apply(configuration, ruleID: Parent.identifier)
                        try $eB.performAfterParseOperations()
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        if inlinableOptionsExist {
                            return
                        } else {
                            throw Issue.invalidConfiguration(ruleID: Parent.description.identifier)
                        }
                    }
                    if !$eA.inlinable {
                    if $eA.key.isEmpty {
                        $eA.key = "e_a"
                    }
                    try eA.apply(configuration[$eA.key], ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    }
                    if !$eB.inlinable {
                        if $eB.key.isEmpty {
                            $eB.key = "e_b"
                        }
                        try eB.apply(configuration[$eB.key], ruleID: Parent.identifier)
                        try $eB.performAfterParseOperations()
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

    func testConfigurationElementsWithKeys() {
        assertMacroExpansion(
            """
            @AutoApply
            struct S {
                @ConfigurationElement(key: "eC")
                var eA = 1
                @ConfigurationElement(key: "eD", other: 7)
                var eB = 2
            }
            """,
            expandedSource:
            """
            struct S {
                @ConfigurationElement(key: "eC")
                var eA = 1
                @ConfigurationElement(key: "eD", other: 7)
                var eB = 2

                mutating func apply(configuration: Any) throws {
                    var inlinableOptionsExist = false
                    if $eA.inlinable {
                    inlinableOptionsExist = true
                    try eA.apply(configuration, ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    }
                    if $eB.inlinable {
                        inlinableOptionsExist = true
                        try eB.apply(configuration, ruleID: Parent.identifier)
                        try $eB.performAfterParseOperations()
                    }
                    guard let configuration = configuration as? [String: Any] else {
                        if inlinableOptionsExist {
                            return
                        } else {
                            throw Issue.invalidConfiguration(ruleID: Parent.description.identifier)
                        }
                    }
                    if !$eA.inlinable {
                    if $eA.key.isEmpty {
                        $eA.key = "e_a"
                    }
                    try eA.apply(configuration[$eA.key], ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    }
                    if !$eB.inlinable {
                        if $eB.key.isEmpty {
                            $eB.key = "e_b"
                        }
                        try eB.apply(configuration[$eB.key], ruleID: Parent.identifier)
                        try $eB.performAfterParseOperations()
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
}
