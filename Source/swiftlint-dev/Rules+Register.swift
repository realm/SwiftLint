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

        func run() async throws {
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
            try registerInTestsBzl(rules)
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

/// Struct to hold processed rule information and shard calculations
private struct ProcessedRulesContext {
    let baseRuleNames: [String]
    let totalShards: Int

    init(ruleFiles: [String], shardSize: Int) {
        self.baseRuleNames = ruleFiles.map { $0.replacingOccurrences(of: ".swift", with: "") }
        guard shardSize > 0, !baseRuleNames.isEmpty else {
            self.totalShards = baseRuleNames.isEmpty ? 0 : 1
            return
        }
        self.totalShards = (baseRuleNames.count + shardSize - 1) / shardSize // Ceiling division
    }
}

private extension SwiftLintDev.Rules.Register {
    /// Number of test classes per shard for optimal parallelization
    private static let shardSize = 25

    /// Common parent directory of testsDirectory
    private var testsParentDirectory: URL {
        testsDirectory.deletingLastPathComponent()
    }

    /// Generate content for BuiltInRules.swift file
    private func generateBuiltInRulesFileContent(rulesImportList: String) -> String {
        """
        // GENERATED FILE. DO NOT EDIT!

        /// The rule list containing all available rules built into SwiftLint.
        public let builtInRules: [any Rule.Type] = [
        \(rulesImportList.indent(by: 4)),
        ]

        """
    }

    /// Generate content for Swift test files
    private func generateSwiftTestFileContent(forTestClasses testClassesString: String) -> String {
        """
        // GENERATED FILE. DO NOT EDIT!

        @testable import SwiftLintBuiltInRules
        @testable import SwiftLintCore
        import TestHelpers

        \(testClassesString)

        """
    }

    /// Generate content for Bazel .bzl files
    private func generateBzlFileContent(macroInvocations: String) -> String {
        #"""
        # GENERATED FILE. DO NOT EDIT!

        load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

        def _generated_test_shard(shard_number, copts, strict_concurrency_copts):
            """Creates a single generated test shard with library and test targets.

            Args:
                shard_number: The shard number as a string
                copts: Common compiler options
                strict_concurrency_copts: Strict concurrency compiler options
            """
            swift_library(
                name = "GeneratedTests_{}.library".format(shard_number),
                testonly = True,
                srcs = ["GeneratedTests/GeneratedTests_{}.swift".format(shard_number)],
                module_name = "GeneratedTests_{}".format(shard_number),
                package_name = "SwiftLint",
                deps = [
                    ":TestHelpers",
                ],
                copts = copts + strict_concurrency_copts,
            )

            swift_test(
                name = "GeneratedTests_{}".format(shard_number),
                visibility = ["//visibility:public"],
                deps = [":GeneratedTests_{}.library".format(shard_number)],
            )

        def generated_tests(copts, strict_concurrency_copts):
            """Creates all generated test targets for SwiftLint rules.

            Args:
                copts: Common compiler options
                strict_concurrency_copts: Strict concurrency compiler options
            """
        \#(macroInvocations)

        """#
    }

    func registerInRulesList(_ ruleFiles: [String]) throws {
        let rulesImportString = ruleFiles
            .map { $0.replacingOccurrences(of: ".swift", with: ".self") }
            .joined(separator: ",\n")
        let builtInRulesFile = rulesDirectory.deletingLastPathComponent()
            .appendingPathComponent("Models", isDirectory: true)
            .appendingPathComponent("BuiltInRules.swift", isDirectory: false)

        let fileContent = generateBuiltInRulesFileContent(rulesImportList: rulesImportString)
        try fileContent.write(to: builtInRulesFile, atomically: true, encoding: .utf8)
    }

    func registerInTests(_ ruleFiles: [String]) throws {
        let rulesContext = ProcessedRulesContext(ruleFiles: ruleFiles, shardSize: Self.shardSize)
        let ruleNames = rulesContext.baseRuleNames
        let totalShards = rulesContext.totalShards

        // Remove old generated files
        let existingFiles = try FileManager.default.contentsOfDirectory(
            at: testsDirectory,
            includingPropertiesForKeys: nil
        )
        for file in existingFiles where file.lastPathComponent.hasPrefix("GeneratedTests") &&
            file.pathExtension == "swift" {
            try FileManager.default.removeItem(at: file)
        }

        // Create sharded test files
        for shardIndex in 0..<totalShards {
            let startIndex = shardIndex * Self.shardSize
            let endIndex = min(startIndex + Self.shardSize, ruleNames.count)
            let shardRules = Array(ruleNames[startIndex..<endIndex])

            let testClasses = shardRules.map { testName in """
                final class \(testName)GeneratedTests: SwiftLintTestCase {
                    func testWithDefaultConfiguration() {
                        verifyRule(\(testName).description)
                    }
                }
                """
            }.joined(separator: "\n\n")

            let shardNumber = shardIndex + 1
            let testFile = testsDirectory.appendingPathComponent(
                "GeneratedTests_\(shardNumber).swift",
                isDirectory: false
            )

            let fileContent = generateSwiftTestFileContent(forTestClasses: testClasses)
            try fileContent.write(to: testFile, atomically: true, encoding: .utf8)
        }
    }

    func registerInTestsBzl(_ ruleFiles: [String]) throws {
        let rulesContext = ProcessedRulesContext(ruleFiles: ruleFiles, shardSize: Self.shardSize)
        let totalShards = rulesContext.totalShards

        // Generate macro calls for each shard
        let shardNumbers = (1...totalShards).map(String.init)
        let macroInvocationsString = shardNumbers.map {
            #"    _generated_test_shard("\#($0)", copts, strict_concurrency_copts)"#
        }.joined(separator: "\n")

        let bzlFile = testsParentDirectory.appendingPathComponent(
            "generated_tests.bzl",
            isDirectory: false
        )

        let fileContent = generateBzlFileContent(macroInvocations: macroInvocationsString)
        try fileContent.write(to: bzlFile, atomically: true, encoding: .utf8)
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
                to: testsParentDirectory
                    .appendingPathComponent("IntegrationTests", isDirectory: true)
                    .appendingPathComponent("default_rule_configurations.yml", isDirectory: false),
                atomically: true,
                encoding: .utf8
            )
    }
}
