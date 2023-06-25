import ArgumentParser
import Foundation
import SwiftLintFramework
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension SwiftLint {
    struct Configure: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Configure SwiftLint")

        @Flag(help: "Colorize output regardless of terminal settings.")
        var color = false
        @Flag(help: "Do not colorize output regardless of terminal settings.")
        var noColor = false
        @Flag(help: "Complete setup automatically.")
        var auto = false
        @Flag(help: "In automatic mode, overwrite any existing configuration.")
        var overwrite = false

        private var shouldColorizeOutput: Bool {
            terminalSupportsColor() && (!noColor || color)
        }

        func run() async throws {
            while try await configure() == false, auto == false {
                if askUser("Do you want to start over?") == false {
                    break
                }
            }
            ExitHelper.successfullyExit()
        }

        private func configure() async throws -> Bool {
            doYouWantToContinue("Welcome to SwiftLint! Do you want to continue?")
            checkForExistingConfiguration()
            checkForExistingChildConfigurations()
            let topLevelDirectories = checkForSwiftFiles()
            let allowZeroLintableFiles = topLevelDirectories.isEmpty ? allowZeroLintableFiles() : false
            let rulesIdentifiersToDisable = try await rulesToDisable(topLevelDirectories)
            let analyzerRuleIdentifiers = analyzerRulesToEnable()
            return try writeConfiguration(
                topLevelDirectories,
                allowZeroLintableFiles,
                rulesIdentifiersToDisable,
                analyzerRuleIdentifiers)
        }

        private func checkForExistingConfiguration() {
            print("Checking for existing \(Configuration.defaultFileName) configuration file.")
            if hasExistingConfiguration() {
                doYouWantToContinue(
                    "Found an existing \(Configuration.defaultFileName) configuration file"
                    + " - Do you want to continue?"
                )
            }
        }

        private func hasExistingConfiguration() -> Bool {
            FileManager.default.fileExists(atPath: Configuration.defaultFileName)
        }

        private func checkForExistingChildConfigurations() {
            print("Checking for any other \(Configuration.defaultFileName) configuration files.")

            let files = FileManager.default.filesWithSuffix(Configuration.defaultFileName).filter {
                $0 != Configuration.defaultFileName
            }
            if files.isNotEmpty {
                print("Found existing child configurations:\n")
                files.forEach { print($0) }
                doYouWantToContinue("\nDo you want to continue?")
            }
        }

        private func checkForSwiftFiles() -> [String] {
            print("Checking for .swift files.")
            let topLevelDirectories = FileManager.default.filesWithSuffix(".swift")
                .compactMap { $0.firstPathComponent }
                .unique
                .filter { !$0.isSwiftFile() }
            if topLevelDirectories.isNotEmpty {
                print("Found .swift files in the following top level directories:\n")
                topLevelDirectories.forEach { print($0) }
                if askUser("\nDo you want SwiftLint to scan all of those directories?") {
                    return topLevelDirectories
                } else {
                    var selectedDirectories: [String] = []
                    topLevelDirectories.forEach {
                        if askUser("Do you want SwiftLint to scan the \($0) directory?") {
                            selectedDirectories.append($0)
                        }
                    }
                    return selectedDirectories
                }
            } else {
                print("No .swift files found.")
                doYouWantToContinue("\nDo you want to continue?")
                return []
            }
        }

        private func allowZeroLintableFiles() -> Bool {
            askUser("Do you want SwiftLint to succeed even if there are no files to lint?")
        }

        private func rulesToDisable(_ topLevelDirectories: [String]) async throws -> [String] {
            var ruleIdentifiersToDisable: [String] = []
            if topLevelDirectories.isNotEmpty {
                ruleIdentifiersToDisable.append(contentsOf: try await checkExistingViolations(topLevelDirectories))
            }
            let deprecatedRuleIdentifiers = Set(RuleRegistry.shared.deprecatedRuleIdentifiers)
            let undisableDeprecatedRuleIdentifiers = deprecatedRuleIdentifiers.subtracting(ruleIdentifiersToDisable)
            if undisableDeprecatedRuleIdentifiers.isNotEmpty {
                if askUser("\nDo you want to disable any deprecated rules?") {
                    ruleIdentifiersToDisable.append(contentsOf: undisableDeprecatedRuleIdentifiers.sorted())
                }
            }
            return ruleIdentifiersToDisable
        }

        private func checkExistingViolations(_ topLevelDirectories: [String]) async throws -> [String] {
            var ruleIdentifiersToDisable: [String] = []
            print("Checking for violations. This may take some time.")
            let configuration = try writeTemporaryConfigurationFile(topLevelDirectories)
            defer {
                try? FileManager.default.removeItem(atPath: configuration)
            }

            let options = LintOrAnalyzeOptions(
                mode: .lint,
                paths: [""],
                useSTDIN: false,
                configurationFiles: [configuration],
                strict: false,
                lenient: true,
                forceExclude: false,
                useExcludingByPrefix: false,
                useScriptInputFiles: false,
                benchmark: false,
                reporter: SummaryReporter.identifier,
                quiet: false,
                output: nil,
                progress: true,
                cachePath: nil,
                ignoreCache: false,
                enableAllRules: true,
                autocorrect: false,
                format: false,
                compilerLogPath: nil,
                compileCommands: nil,
                inProcessSourcekit: false
            )

            Issue.printDeprecationWarnings = false
            let violations = try await LintOrAnalyzeCommand.lintOrAnalyze(options)
            if violations.isNotEmpty {
                if askUser("\nDo you want to disable all of the SwiftLint rules with existing violations?") {
                    let dictionary = Dictionary(grouping: violations) { $0.ruleIdentifier }
                    ruleIdentifiersToDisable = dictionary.keys.sorted {
                        if dictionary[$0]!.count != dictionary[$1]!.count {
                            return dictionary[$0]!.count > dictionary[$1]!.count
                        } else {
                            return $0 > $1
                        }
                    }
                }
            }

            return ruleIdentifiersToDisable
        }

        private func analyzerRulesToEnable() -> [String] {
            let analyzerRuleIdentifiers = RuleRegistry.shared.analyzerRuleIdentifiers.sorted()
            if askUser("\nDo you want to enable all (\(analyzerRuleIdentifiers.count)) of the analyzer rules?") {
                return analyzerRuleIdentifiers
            } else {
                return []
            }
        }

        private func writeConfiguration(
            _ topLevelDirectories: [String],
            _ allowZeroLintableFiles: Bool,
            _ ruleIdentifiersToDisable: [String],
            _ analyzerRuleIdentifiers: [String]
        ) throws -> Bool {
            var configuration = configuration(forTopLevelDirectories: topLevelDirectories)
            if allowZeroLintableFiles {
                configuration += "allow_zero_lintable_files: true\n"
            }
            configuration += "disabled_rules:\n"
            ruleIdentifiersToDisable.forEach { configuration += "  - \($0)\n" }
            if analyzerRuleIdentifiers.isNotEmpty {
                configuration += "analyzer_rules:\n"
                analyzerRuleIdentifiers.forEach { configuration += "  - \($0)\n" }
            }
            print("Proposed configuration\n")
            print(configuration)
            if askUser("Does that look good?") == false {
                return false
            }
            if hasExistingConfiguration() {
                if auto && overwrite {
                    print("Overwriting existing configuration.")
                    try writeConfiguration(configuration)
                    return true
                } else {
                    print("Found an existing configuration.")
                    if !askUser("Do you want to exit without overwriting the existing configuration?") {
                        if askUser("Do you want to overwrite the existing configuration?") {
                            try writeConfiguration(configuration)
                            return true
                        }
                    }
                }
            } else {
                if askUser("Do you want to save the configuration?") {
                    try writeConfiguration(configuration)
                    return true
                }
            }

            return false
        }

        private func writeConfiguration(_ configuration: String) throws {
            print("Saving configuration to \(Configuration.defaultFileName)")
            try configuration.write(toFile: Configuration.defaultFileName, atomically: true, encoding: .utf8)
        }

        private func configuration(
            forTopLevelDirectories topLevelDirectories: [String],
            path: String? = nil
        ) -> String {
            var configuration = "included:\n"
            topLevelDirectories.forEach {
                let absolutePath: String
                if let path {
                    absolutePath = path.bridge().appendingPathComponent($0)
                } else {
                    absolutePath = $0
                }
                configuration += "  - \(absolutePath)\n"
            }
            configuration += "opt_in_rules:\n  - all\n"
            return configuration
        }

        private func writeTemporaryConfigurationFile(_ topLevelDirectories: [String]) throws -> String {
            let configuration = configuration(
                forTopLevelDirectories: topLevelDirectories,
                path: FileManager.default.currentDirectoryPath
            )
            let filename = ".\(UUID().uuidString)\(Configuration.defaultFileName)"
            let filePath = FileManager.default.temporaryDirectory.path.bridge().appendingPathComponent(filename)
            try configuration.write(toFile: filePath, atomically: true, encoding: .utf8)
            return filePath
        }

        private func askUser(_ message: String) -> Bool {
            swiftlint.askUser(message, colorizeOutput: shouldColorizeOutput, auto: auto)
        }

        private func doYouWantToContinue(_ message: String) {
            if !askUser(message) {
                ExitHelper.successfullyExit()
            }
        }
    }
}

private func askUser(_ message: String, colorizeOutput: Bool, auto: Bool) -> Bool {
    let message = "\(message) (Y/n)"
    let colorizedMessage = colorizeOutput ? message.boldify : message
    while true {
        print(colorizedMessage, terminator: auto ? "\n" : " ")
        if auto {
            return true
        }
        if let character = readLine() {
            if character.isEmpty || character.lowercased() == "y" {
                return true
            } else if character.lowercased() == "n" {
                return false
            } else {
                print("Invalid Response")
            }
        }
    }
}

private func print(_ message: String, terminator: String = "\n") {
    Swift.print(message, terminator: terminator)
    fflush(stdout)
}

private func terminalSupportsColor() -> Bool {
    if
        isatty(1) != 0, let term = ProcessInfo.processInfo.environment["TERM"],
        term.contains("color"), term.contains("256")
    {
        return true
    }
    return false
}

private extension String {
    var boldify: String {
        "\u{001B}[0;1m\(self)\u{001B}[0;0m"
    }
    var firstPathComponent: String? {
        components(separatedBy: "/").first
    }
}

private extension FileManager {
    func filesWithSuffix(_ fileName: String) -> [String] {
        var results: [String] = []
        let directoryEnumerator = enumerator(atPath: currentDirectoryPath)
        while let file = directoryEnumerator?.nextObject() as? String {
            if file.hasSuffix(fileName) {
                results.append(file)
            }
        }
        return results
    }
}

private extension RuleRegistry {
    var deprecatedRuleIdentifiers: [String] {
        RuleRegistry.shared.list.list.compactMap { ruleID, ruleType in
            ruleType is DeprecatedRule.Type ? ruleID : nil
        }
    }
    var analyzerRuleIdentifiers: [String] {
        RuleRegistry.shared.list.list.compactMap { ruleID, ruleType in
            ruleType is AnalyzerRule.Type ? ruleID : nil
        }
    }
}
