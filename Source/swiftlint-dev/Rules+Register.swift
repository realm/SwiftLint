import ArgumentParser
import Foundation

extension SwiftLintDev.Rules {
    struct Register: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "register",
            abstract: "Register rules as provided by SwiftLint.",
            discussion: """
                This command registers rules in the list of officially provided built-in rules. It also
                adds test cases verifying the examples defined in these rules' descriptions.
                """
        )

        private var rulesDirectory: URL {
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Source", isDirectory: true)
                .appendingPathComponent("SwiftLintBuiltInRules", isDirectory: true)
                .appendingPathComponent("Rules", isDirectory: true)
        }

        func run() async throws {
            guard FileManager.default.fileExists(atPath: rulesDirectory.path) else {
                throw ValidationError("Command must be run from the root of the SwiftLint repository.")
            }
            let enumerator = FileManager.default.enumerator(at: rulesDirectory, includingPropertiesForKeys: nil)
            guard let enumerator else {
                throw ValidationError(
                    "Failed to enumerate rule files in \(rulesDirectory.relativeToCurrentDirectory)."
                )
            }
            let rules = enumerator
                .compactMap { ($0 as? URL)?.lastPathComponent }
                .filter { $0.hasSuffix("Rule.swift") }
                .sorted()
            try registerInRulesList(rules)
            try registerInTests(rules)
            print("(Re-)Registered \(rules.count) rules.")
        }
    }
}

private extension SwiftLintDev.Rules.Register {
    func registerInRulesList(_ ruleFiles: [String]) throws {
        let rules = ruleFiles
            .map { $0.replacingOccurrences(of: ".swift", with: ".self") }
            .joined(separator: ",\n")
        let builtInRulesFile = rulesDirectory.deletingLastPathComponent()
            .appendingPathComponent("Models", isDirectory: true)
            .appendingPathComponent("BuiltInRules.swift", isDirectory: false)
        try """
            // GENERATED FILE. DO NOT EDIT!

            /// The rule list containing all available rules built into SwiftLint.
            public let builtInRules: [any Rule.Type] = [
            \(rules.indent(by: 4)),
            ]

            """.write(to: builtInRulesFile, atomically: true, encoding: .utf8)
    }

    func registerInTests(_ ruleFiles: [String]) throws {
        let testsDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Tests", isDirectory: true)
            .appendingPathComponent("GeneratedTests", isDirectory: true)
        guard FileManager.default.fileExists(atPath: testsDirectory.path) else {
            throw ValidationError("Command must be run from the root of the SwiftLint repository.")
        }
        let testFile = testsDirectory.appendingPathComponent("GeneratedTests.swift", isDirectory: false)
        let rules = ruleFiles
            .map { $0.replacingOccurrences(of: ".swift", with: "") }
            .map { testName in """
                final class \(testName)GeneratedTests: SwiftLintTestCase {
                    func testWithDefaultConfiguration() {
                        verifyRule(\(testName).description)
                    }
                }
                """
            }
            .joined(separator: "\n\n")

        try """
            // GENERATED FILE. DO NOT EDIT!

            @testable import SwiftLintBuiltInRules
            @testable import SwiftLintCore
            import TestHelpers

            // swiftlint:disable:next blanket_disable_command
            // swiftlint:disable file_length single_test_class type_name

            \(rules)

            """.write(to: testFile, atomically: true, encoding: .utf8)
    }
}
