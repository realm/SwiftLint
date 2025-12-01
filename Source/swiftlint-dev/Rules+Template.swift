import ArgumentParser
import Foundation
import SwiftLintCore

extension SwiftLintDev.Rules {
    struct Template: AsyncParsableCommand {
        // swiftlint:disable:next force_try
        private static let camelCaseRegex = try! NSRegularExpression(pattern: "(?<!^)(?=[A-Z])")

        static let configuration = CommandConfiguration(
            commandName: "template",
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
        var severity = ViolationSeverity.warning
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
        @Flag(name: .long, help: "Do not add example code.")
        var noExamples = false
        @Flag(name: .long, help: "Skip registration.")
        var skipRegistration = false

        func run() throws {
            let rootDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let ruleDirectory = rootDirectory
                .appendingPathComponent("Source", isDirectory: true)
                .appendingPathComponent("SwiftLintBuiltInRules", isDirectory: true)
                .appendingPathComponent("Rules", isDirectory: true)
            let ruleLocation = ruleDirectory.appendingPathComponent(kind.rawValue.capitalized, isDirectory: true)
            guard FileManager.default.fileExists(atPath: ruleLocation.path) else {
                throw ValidationError("Command must be run from the root of the SwiftLint repository.")
            }
            print("Creating template(s) for new rule \"\(ruleName)\" identified by '\(ruleId)' ...")
            let rulePath = ruleLocation.appendingPathComponent("\(name)Rule.swift", isDirectory: false)
            guard overwrite || !FileManager.default.fileExists(atPath: rulePath.path) else {
                throw ValidationError("Rule file already exists at \(rulePath.relativeToCurrentDirectory).")
            }
            try ruleTemplate.write(toFile: rulePath.path, atomically: true, encoding: .utf8)
            print("Rule file created at \(rulePath.relativeToCurrentDirectory).")
            if config {
                let configPath = ruleDirectory
                    .appendingPathComponent("RuleConfigurations", isDirectory: true)
                    .appendingPathComponent("\(name)Configuration.swift", isDirectory: false)
                guard overwrite || !FileManager.default.fileExists(atPath: configPath.path) else {
                    throw ValidationError(
                        "Configuration file already exists at \(configPath.relativeToCurrentDirectory)."
                    )
                }
                try configTemplate.write(toFile: configPath.path, atomically: true, encoding: .utf8)
                print("Configuration file created at \(configPath.relativeToCurrentDirectory).")
            }
            if test {
                let testDirectory = rootDirectory
                    .appendingPathComponent("Tests", isDirectory: true)
                    .appendingPathComponent("BuiltInRulesTests", isDirectory: true)
                let testPath = testDirectory.appendingPathComponent("\(name)RuleTests.swift", isDirectory: false)
                guard FileManager.default.fileExists(atPath: testDirectory.path) else {
                    throw ValidationError("Command must be run from the root of the SwiftLint repository.")
                }
                guard overwrite || !FileManager.default.fileExists(atPath: testPath.path) else {
                    throw ValidationError("Test file already exists at \(testPath.relativeToCurrentDirectory).")
                }
                try testTemplate.write(toFile: testPath.path, atomically: true, encoding: .utf8)
                print("Test file created at \(testPath.relativeToCurrentDirectory).")
            }
            if !skipRegistration {
                try Register().runFor(newRule: .init(
                    identifier: ruleId,
                    yamlConfig: """
                        severity: \(severity)
                        """,
                    optIn: !`default`,
                    correctable: correctable || rewriter
                ))
            }
        }
    }
}

private extension SwiftLintDev.Rules.Template {
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
        attributeArguments.append("optIn: \(!`default`)")
        var ruleDescriptionArguments = [
            "identifier: \"\(ruleId)\"",
            "name: \"\(ruleName)\"",
            "description: \"\"",
            "kind: .\(kind.rawValue)",
            """
            nonTriggeringExamples: [
                Example("\(noExamples ? "" : "let x = 1")"),
            ]
            """,
            """
            triggeringExamples: [
                Example("\(noExamples ? "" : "var ↓foo = 1")"),
            ]
            """,
        ]
        if correctable || rewriter {
            ruleDescriptionArguments.append("""
                corrections: [
                    Example("\(noExamples ? "" : "let foo = 1")"):
                        Example("\(noExamples ? "" : "let bar = 1")"),
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
                \(noExamples ? "" : """
                    override func visitPost(_ node: VariableDeclSyntax) {
                        node.bindings.forEach { binding in
                            if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                               pattern.identifier.text == "foo" {
                                violations.append(.init(
                                    position: pattern.positionAfterSkippingLeadingTrivia,
                                    reason: "Variable named 'foo' should be named 'bar' instead"
                                ))
                            }
                        }
                    }
                    """.indent(by: 4, skipFirst: true)
                )
            }
            """,
        ]
        if rewriter {
            extensionContent.append("""

                final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
                    \(noExamples ? "" : """
                        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
                            let bindings = node.bindings.map { binding in
                                if let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                                pattern.identifier.text == "foo" {
                                    numberOfCorrections += 1
                                    return binding.with(
                                        \\.pattern,
                                        PatternSyntax(pattern.with(\\.identifier, .identifier("bar")))
                                            .with(\\.trailingTrivia, pattern.trailingTrivia)
                                    )
                                }
                                return binding
                            }
                            return super.visit(node.with(\\.bindings, PatternBindingListSyntax(bindings)))
                        }
                        """.indent(by: 4, skipFirst: true)
                    )
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
            @ConfigurationElement(key: "severity")
            private(set) var severityConfiguration = SeverityConfiguration<Parent>(.\(severity))
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
