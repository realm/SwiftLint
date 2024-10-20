import ArgumentParser
import Foundation
import SwiftLintFramework
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

// swiftlint:disable file_length
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
            _ = try await configure()
            ExitHelper.successfullyExit()
        }

        private func configure() async throws -> Bool {
            doYouWantToContinue("Welcome to SwiftLint! Do you want to continue?")
            let existingConfiguration = checkForExistingConfiguration()
            checkForExistingChildConfigurations()
            let topLevelDirectories = checkForSwiftFiles()
            let allowZeroLintableFiles = topLevelDirectories.isEmpty ? allowZeroLintableFiles() : false
            let rulesIdentifiersToDisable = try await rulesToDisable(
                topLevelDirectories,
                configuration: existingConfiguration
            )
            let analyzerRuleIdentifiers = analyzerRulesToEnable()
            let reporterIdentifier = reporterIdentifier()
            return try writeConfiguration(
                topLevelDirectories: topLevelDirectories,
                allowZeroLintableFiles: allowZeroLintableFiles,
                ruleIdentifiersToDisable: rulesIdentifiersToDisable,
                analyzerRuleIdentifiers: analyzerRuleIdentifiers,
                existingConfiguration: existingConfiguration,
                reporterIdentifier: reporterIdentifier
            )
        }

        private func checkForExistingConfiguration() -> Configuration? {
            let fileName = Configuration.defaultFileName
            print("Checking for existing \(fileName) configuration file.")
            if hasExistingConfiguration() {
                doYouWantToContinue(
                    "Found an existing \(fileName) configuration file"
                    + " - Do you want to continue?"
                )
                if askUser("Do you want to you want to keep any custom configurations from \(fileName)") {
                    return Configuration(configurationFiles: [fileName])
                }
            }
            return nil
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
                }
                var selectedDirectories: [String] = []
                topLevelDirectories.forEach {
                    if askUser("Do you want SwiftLint to scan the \($0) directory?") {
                        selectedDirectories.append($0)
                    }
                }
                return selectedDirectories
            }
            doYouWantToContinue("No .swift files found. Do you want to continue?")
            return []
        }

        private func allowZeroLintableFiles() -> Bool {
            askUser("Do you want SwiftLint to succeed even if there are no files to lint?")
        }

        private func rulesToDisable(
            _ topLevelDirectories: [String],
            configuration: Configuration?
        ) async throws -> [String] {
            var ruleIdentifiersToDisable: [String] = []
            if topLevelDirectories.isNotEmpty {
                let rulesWithExistingViolations = try await checkExistingViolations(
                    topLevelDirectories,
                    configuration: configuration
                )
                ruleIdentifiersToDisable.append(contentsOf: rulesWithExistingViolations)
            }
            let deprecatedRuleIdentifiers = Set(RuleRegistry.shared.deprecatedRuleIdentifiers)
            let undisabledDeprecatedRuleIdentifiers = deprecatedRuleIdentifiers.subtracting(ruleIdentifiersToDisable)
            if undisabledDeprecatedRuleIdentifiers.isNotEmpty {
                let count = undisabledDeprecatedRuleIdentifiers.count
                if askUser("\nDo you want to disable all (\(count)) of the deprecated rules?") {
                    ruleIdentifiersToDisable.append(contentsOf: undisabledDeprecatedRuleIdentifiers.sorted())
                }
            }
            return ruleIdentifiersToDisable
        }

        private func checkExistingViolations(
            _ topLevelDirectories: [String],
            configuration: Configuration?
        ) async throws -> [String] {
            var ruleIdentifiersToDisable: [String] = []
            print("Checking for violations. This may take some time.")
            let configurationPath = try writeTemporaryConfigurationFile(
                topLevelDirectories,
                configuration: configuration
            )
            defer {
                // try? FileManager.default.removeItem(atPath: configurationPath)
            }

            let options = LintOrAnalyzeOptions(
                mode: .lint,
                paths: [""],
                useSTDIN: false,
                configurationFiles: [configurationPath],
                strict: false,
                lenient: false,
                forceExclude: false,
                useExcludingByPrefix: false,
                useScriptInputFiles: false,
                benchmark: false,
                reporter: "summary", // SummaryReporter.identifier,
                baseline: nil,
                writeBaseline: nil,
                workingDirectory: nil,
                quiet: false,
                output: nil,
                progress: true,
                cachePath: nil,
                ignoreCache: false,
                enableAllRules: true,
                onlyRule: nil,
                autocorrect: false,
                format: false,
                compilerLogPath: nil,
                compileCommands: nil,
                checkForUpdates: false
            )

            Issue.printDeprecationWarnings = false
            let violations = try await LintOrAnalyzeCommand.lintOrAnalyze(options)
            if violations.isNotEmpty {
                if askUser("\nDo you want to disable all of the SwiftLint rules with existing violations?") {
                    let dictionary = Dictionary(grouping: violations) { $0.ruleIdentifier }
                    ruleIdentifiersToDisable = dictionary.keys.sorted {
                        if dictionary[$0]!.count != dictionary[$1]!.count {
                            return dictionary[$0]!.count > dictionary[$1]!.count
                        }
                        return $0 > $1
                    }
                }
            }

            return ruleIdentifiersToDisable
        }

        private func analyzerRulesToEnable() -> [String] {
            let analyzerRuleIdentifiers = RuleRegistry.shared.analyzerRuleIdentifiers.sorted()
            if askUser("\nDo you want to enable all (\(analyzerRuleIdentifiers.count)) of the analyzer rules?") {
                return analyzerRuleIdentifiers
            }
            if askUser("\nDo you want to enable any of the analyzer rules?") {
                var analyzerRulesToEnable: [String] = []
                RuleRegistry.shared.analyzerRuleIdentifiers.forEach {
                    if askUser("Do you want to enable the \($0) analyzer rule?") {
                        analyzerRulesToEnable.append($0)
                    }
                }
                return analyzerRulesToEnable
            }
            return []
        }

        private func reporterIdentifier() -> String {
            // var reporterIdentifier = XcodeReporter.identifier
            var reporterIdentifier = "xcode"
            if askUser("Do you want to use the default (\(reporterIdentifier)) reporter?") {
                return reporterIdentifier
            }
            reporterIdentifier = ""
            while !isValidReporterIdentifier(reporterIdentifier) {
                if reporterIdentifier.isNotEmpty {
                    print("'\(reporterIdentifier)' is not a valid reporter identifier")
                }
                print("Available reporters:")
                print(Reporters.reportersTable())
                reporterIdentifier = askUserWhichReporter()
            }
            return reporterIdentifier
        }

        private func isValidReporterIdentifier(_ reporterIdentifier: String) -> Bool {
            reportersList.contains { $0.identifier == reporterIdentifier }
        }

        // swiftlint:disable:next function_parameter_count
        private func writeConfiguration(
            topLevelDirectories: [String],
            allowZeroLintableFiles: Bool,
            ruleIdentifiersToDisable: [String],
            analyzerRuleIdentifiers: [String],
            existingConfiguration: Configuration?,
            reporterIdentifier: String
        ) throws -> Bool {
            var configurationYML = configurationYML(forTopLevelDirectories: topLevelDirectories)
            if allowZeroLintableFiles {
                configurationYML += "allow_zero_lintable_files: true\n"
            }
            configurationYML += "disabled_rules:\n"
            ruleIdentifiersToDisable.sorted().forEach { configurationYML += "  - \($0)\n" }
            if analyzerRuleIdentifiers.isNotEmpty {
                configurationYML += "analyzer_rules:\n"
                analyzerRuleIdentifiers.forEach { configurationYML += "  - \($0)\n" }
            }
            configurationYML += "reporter: \(reporterIdentifier)\n"
            if let existingConfiguration {
                configurationYML += "\n"
                configurationYML += existingConfiguration.customYML
            }
            print("Proposed configuration\n")
            print(configurationYML)
            if askUser("Does that look good?") == false {
                return false
            }
            if hasExistingConfiguration() {
                if auto && overwrite {
                    print("Overwriting existing configuration.")
                    try writeConfigurationYML(configurationYML)
                    return true
                }
                print("Found an existing configuration.")
                if !askUser("Do you want to exit without overwriting the existing configuration?") {
                    if askUser("Do you want to overwrite the existing configuration?") {
                        try writeConfigurationYML(configurationYML)
                        return true
                    }
                }
            } else {
                if askUser("Do you want to save the configuration?") {
                    try writeConfigurationYML(configurationYML)
                    return true
                }
            }

            return false
        }

        private func writeConfigurationYML(_ configurationYML: String) throws {
            print("Saving configuration to \(Configuration.defaultFileName)")
            try configurationYML.write(toFile: Configuration.defaultFileName, atomically: true, encoding: .utf8)
        }

        private func configurationYML(
            forTopLevelDirectories topLevelDirectories: [String],
            path: String? = nil,
            configuration: Configuration? = nil
        ) -> String {
            var configurationYML = "included:\n"
            topLevelDirectories.forEach { directory in
                let absolutePath: String
                if let path {
                    absolutePath = path.bridge().appendingPathComponent(directory)
                } else {
                    absolutePath = directory
                }
                configurationYML += "  - \(absolutePath)\n"
            }
            configurationYML += "opt_in_rules:\n  - \(RuleIdentifier.all.stringRepresentation)\n"
            configurationYML += "analyzer_rules:\n"
            RuleRegistry.shared.analyzerRuleIdentifiers.forEach {
                configurationYML += "  - \($0)\n"
            }
            if let configuration {
                configurationYML += configuration.customYML
            }
            return configurationYML
        }

        private func writeTemporaryConfigurationFile(
            _ topLevelDirectories: [String],
            configuration: Configuration?
        ) throws -> String {
            let temporaryConfiguration = configurationYML(
                forTopLevelDirectories: topLevelDirectories,
                path: FileManager.default.currentDirectoryPath,
                configuration: configuration
            )
            let filename = ".\(UUID().uuidString)\(Configuration.defaultFileName)"
            let filePath = FileManager.default.temporaryDirectory.path.bridge().appendingPathComponent(filename)
            print(">>>> filePath = \(filePath)")
            try temporaryConfiguration.write(toFile: filePath, atomically: true, encoding: .utf8)
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

        private func askUserWhichReporter() -> String {
            let message = "Which reporter would you like to use?"
            let colorizedMessage = shouldColorizeOutput ? message.boldify : message
            while true {
                print(colorizedMessage, terminator: " ")
                if let reporterIdentifier = readLine() {
                    if reporterIdentifier.isNotEmpty {
                        return reporterIdentifier
                    }
                }
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
            }
            if character.lowercased() == "n" {
                return false
            }
            print("Invalid Response")
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
        term.contains("color"), term.contains("256") {
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
            ruleType is any DeprecatedRule.Type ? ruleID : nil
        }
    }
    var analyzerRuleIdentifiers: [String] {
        RuleRegistry.shared.list.list.compactMap { ruleID, ruleType in
            ruleType is any AnalyzerRule.Type ? ruleID : nil
        }
    }
}

private extension Configuration {
    var customYML: String {
        let customYML = ""
        for rule in rules {
            let ruleIdentifier = type(of: rule).description.identifier
            guard ruleIdentifier != "file_name", ruleIdentifier != "required_enum_case" else {
                continue
            }
//            if rule.configurationDescription.hasContent {
//                let defaultRule = type(of: rule).init()
//                let defaultYML = defaultRule.configurationDescription.yaml()
//                let ruleYML = rule.configurationDescription.yaml()
//                if ruleYML != defaultYML {
//                    customYML += """
//
//                             \(type(of: rule).description.identifier):
//                             \(ruleYML.indent(by: 4))
//
//                             """
//                }
//            }
        }
        return customYML
    }
}
