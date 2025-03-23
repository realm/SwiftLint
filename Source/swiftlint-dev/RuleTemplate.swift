import ArgumentParser
import Foundation
import SwiftLintCore

extension SwiftLintDev {
    struct RuleTemplate: AsyncParsableCommand {
        // swiftlint:disable:next force_try
        private static let camelCaseRegex = try! NSRegularExpression(pattern: "(?<!^)(?=[A-Z])")

        static let configuration = CommandConfiguration(
            commandName: "rule-template",
            abstract: "Generate a template for a new SwiftLint rule.",
            discussion: """
                This command generates a template for a SwiftLint rule. It creates a new file with the
                specified rule name and populates it with a basic structure. Optional flags allow you to
                customize the rule's properties.
                """
        )

        @Argument(help: "The name of the rule in PascalCase.")
        var name: String
        @Option(name: .long, help: "The rule's identifier. Defaults to the rule name in snake_case.")
        var id: String?
        @Option(name: .long, help: "Type of the rule.")
        var kind: RuleKind = .lint
        @Option(name: .long, help: "The rule's default severity.")
        var severity: ViolationSeverity = .warning
        @Flag(name: .long, help: "Indicates whether the rule shall be enabled by default.")
        var `default` = false
        @Flag(name: .long, help: "Indicates whether the rule is correctable.")
        var correctable = false
        @Flag(name: .long, help: "Indicates whether the rule has a custom rewriter.")
        var rewriter = false
        @Flag(name: .long, help: "Indicates whether the rule has a custom configuration.")
        var config = false
        @Flag(name: .long, help: "Indicates whether this rule has a dedicated test. This is usually not necessary.")
        var test = false
        @Flag(name: .long, help: "Indicates whether to overwrite existing files. Use with caution!")
        var overwrite = false

        func run() async throws {
            let ruleDirectory = "Source/SwiftLintBuiltInRules/Rules"
            let ruleLocation = "\(ruleDirectory)/\(kind.rawValue.capitalized)"
            guard FileManager.default.fileExists(atPath: ruleLocation) else {
                throw ValidationError("Command must be run from the root of the SwiftLint repository.")
            }
            print("Creating template(s) for new rule \"\(ruleName)\" identified by '\(ruleId)' ...")
            let rulePath = "\(ruleLocation)/\(name)Rule.swift"
            guard overwrite || !FileManager.default.fileExists(atPath: rulePath) else {
                throw ValidationError("Rule file already exists at \(rulePath).")
            }
            try ruleTemplate.write(toFile: rulePath, atomically: true, encoding: .utf8)
            print("Rule file created at \(rulePath).")
            guard config else {
                return
            }
            let configPath = "\(ruleDirectory)/RuleConfigurations/\(name)Configuration.swift"
            guard overwrite || !FileManager.default.fileExists(atPath: configPath) else {
                throw ValidationError("Configuration file already exists at \(configPath).")
            }
            try configTemplate.write(toFile: configPath, atomically: true, encoding: .utf8)
            print("Configuration file created at \(configPath).")
            guard test else {
                return
            }
            let testDirectory = "Tests/BuiltInRulesTests"
            let testPath = "\(testDirectory)/\(name)RuleTests.swift"
            guard FileManager.default.fileExists(atPath: testDirectory) else {
                throw ValidationError("Command must be run from the root of the SwiftLint repository.")
            }
            guard overwrite || !FileManager.default.fileExists(atPath: testPath) else {
                throw ValidationError("Test file already exists at \(testPath).")
            }
            try testTemplate.write(toFile: testPath, atomically: true, encoding: .utf8)
            print("Test file created at \(testPath).")
        }
    }
}

private extension SwiftLintDev.RuleTemplate {
    var ruleId: String {
        id ?? Self.camelCaseRegex.stringByReplacingMatches(
            in: name,
            range: NSRange(location: 0, length: name.utf16.count),
            withTemplate: "_$0"
        ).lowercased()
    }

    var ruleName: String {
        Self.camelCaseRegex.stringByReplacingMatches(
            in: name,
            range: NSRange(location: 0, length: name.utf16.count),
            withTemplate: " $0"
        )
    }

    var ruleTemplate: String {
        var attributeArguments = [String]()
        if rewriter {
            attributeArguments.append("explicitRewriter: true")
        }
        if correctable, !rewriter {
            attributeArguments.append("correctable: true")
        }
        attributeArguments.append("optIn: \(`default`)")
        var ruleDescriptionArguments = [
            "identifier: \"\(ruleId)\"",
            "name: \"\(ruleName)\"",
            "description: \"\"",
            "kind: .\(kind.rawValue)",
            """
            nonTriggeringExamples: [
                Example(""),
            ]
            """,
            """
            triggeringExamples: [
                Example(""),
            ]
            """,
        ]
        if correctable || rewriter {
            ruleDescriptionArguments.append("""
                corrections: [
                    Example(""):
                        Example(""),
                ]
                """)
        }
        let configDecl = "var configuration = " + (
            config
                ? "\(name)Configuration()"
                : "SeverityConfiguration<Self>(.\(severity))"
        )
        var extensionContent = [
            """
            final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
            }
            """,
        ]
        if rewriter {
            extensionContent.append("""

                final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
                }
                """)
        }
        return """
            import SwiftLintCore
            import SwiftSyntax

            @SwiftSyntaxRule(\(attributeArguments.joined(separator: ", ")))
            struct \(name)Rule: Rule {
                \(configDecl)

                static let description = RuleDescription(
                    \(ruleDescriptionArguments.joined(separator: ",\n").indent(by: 8, skipFirst: true))
                )
            }

            private extension \(name)Rule {
                \(extensionContent.joined(separator: "\n").indent(by: 4, skipFirst: true))
            }

            """
    }

    var configTemplate: String {
        """
        import SwiftLintCore

        @AutoConfigParser
        struct \(name)Configuration: SeverityBasedRuleConfiguration {
            typealias Parent = \(name)Rule

            @ConfigurationElement(key: "severity")
            private(set) var severityConfiguration = SeverityConfiguration<Parent>(.error)
        }

        """
    }

    var testTemplate: String {
        """
        @testable import SwiftLintBuiltInRules
        import TestHelpers

        final class \(name)RuleTests: SwiftLintTestCase {
            func test() {
                verifyRule(\(name)Rule.description, ruleConfiguration: [])
            }
        }

        """
    }
}

extension RuleKind: ExpressibleByArgument {
    // Automatic conformance.
}

extension ViolationSeverity: ExpressibleByArgument {
    // Automatic conformance.
}
