import ArgumentParser
import Foundation
import SwiftLintFramework

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

        private var testsDirectory: URL {
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Tests", isDirectory: true)
                .appendingPathComponent("GeneratedTests", isDirectory: true)
        }

        func run() throws {
            try runFor(newRule: nil)
        }

        func runFor(newRule: NewRuleDetails?) throws {
            guard FileManager.default.fileExists(atPath: rulesDirectory.path),
                  FileManager.default.fileExists(atPath: testsDirectory.path) else {
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
            try registerInTestReference(adding: newRule)
            print("(Re-)Registered \(rules.count) rules.")
        }
    }
}

struct NewRuleDetails: Equatable {
    let identifier: String
    let yamlConfig: String
    let optIn: Bool
    let correctable: Bool

    var yaml: String {
        """
        \(identifier):
        \(yamlConfig.indent(by: 2))
          meta:
            opt-in: \(optIn)
            correctable: \(correctable)
        """
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
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
        let testFile = testsDirectory
            .appendingPathComponent("GeneratedTests.swift", isDirectory: false)
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

    func registerInTestReference(adding newRule: NewRuleDetails?) throws {
        RuleRegistry.registerAllRulesOnce()
        var ruleDetails = Configuration(rulesMode: .allCommandLine).rules
            .map { type(of: $0) }
            .filter { $0.identifier != "custom_rules" }
            .map { ruleType in
                let rule = ruleType.init()
                return NewRuleDetails(
                    identifier: ruleType.identifier,
                    yamlConfig: rule.createConfigurationDescription().yaml(),
                    optIn: rule is any OptInRule,
                    correctable: rule is any CorrectableRule
                )
            }
        if let newRule {
            ruleDetails.append(newRule)
        }
        try ruleDetails
            .sorted { $0.identifier < $1.identifier }
            .unique
            .map(\.yaml)
            .joined(separator: "\n")
            .appending("\n")
            .write(
                to: testsDirectory.deletingLastPathComponent()
                    .appendingPathComponent("IntegrationTests", isDirectory: true)
                    .appendingPathComponent("default_rule_configurations.yml", isDirectory: false),
                atomically: true,
                encoding: .utf8
            )
    }
}
