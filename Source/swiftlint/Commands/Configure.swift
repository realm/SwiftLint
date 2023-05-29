import ArgumentParser
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
            doYouWantToContinue("Welcome to SwiftLint! Do you want to continue?")
            checkForExistingConfiguration()
            checkForExistingChildConfigurations()
            let topLevelDirectories = checkForSwiftFiles()
            let rulesToDisable = try await rulesToDisable(topLevelDirectories)
            _ = try writeConfiguration(topLevelDirectories, rulesToDisable)
            ExitHelper.successfullyExit()
        }

        private func checkForExistingConfiguration() {
            print("Checking for existing \(Configuration.defaultFileName) configuration file.")
            if hasExistingConfiguration() {
                doYouWantToContinue("Found an existing \(Configuration.defaultFileName) configuration file - Do you want to continue?")
            }
        }

        private func hasExistingConfiguration() -> Bool {
            FileManager.default.fileExists(atPath: Configuration.defaultFileName)
        }

        private func checkForExistingChildConfigurations() {
            print("Checking for any other \(Configuration.defaultFileName) configuration files.")
            let files = FileManager.default.filesWithSuffix(Configuration.defaultFileName).filter { $0 != Configuration.defaultFileName }
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
                    for topLevelDirectory in topLevelDirectories {
                        if askUser("Do you want SwiftLint to scan the \(topLevelDirectory) directory?") {
                            selectedDirectories.append(topLevelDirectory)
                        }
                    }
                    return selectedDirectories
                }
            } else {
                print("No .swift files found.")
                doYouWantToContinue("\nDo you want to continue? (Y/n)")
                return []
            }
        }

        private func rulesToDisable(_ topLevelDirectories: [String]) async throws -> [String] {
            var ruleIdentifiersToDisable: [String] = []
            print("Checking for violations.")
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
                reporter: "summary",
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

        private func writeConfiguration(_ topLevelDirectories: [String], _ rulesToDisable: [String]) throws -> Bool {
            var configuration = configuration(forTopLevelDirectories: topLevelDirectories)
            configuration += "disabled_rules:\n"
            rulesToDisable.forEach { configuration += "  - \($0)\n" }
            print("Proposed configuration\n")
            print(configuration)
            if hasExistingConfiguration() {
                if auto && overwrite {
                    print("Overwriting existing configuration.")
                    try writeConfiguration(configuration)
                    return true
                } else {
                    print("Found an existing configuration.")
                    if !askUser("Do you want to exit without overwriting the existing configuration?") {
                        doYouWantToContinue("Overwrite the existing configuration?")
                        try writeConfiguration(configuration)
                        return true
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

        private func configuration(forTopLevelDirectories topLevelDirectories: [String], path: String? = nil) -> String {
            var configuration = "included:\n"
            topLevelDirectories.forEach {
                let absolutePath: String
                if let path = path {
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
            let configuration = configuration(forTopLevelDirectories: topLevelDirectories, path: FileManager.default.currentDirectoryPath)
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
            if character == "" || character.lowercased() == "y" {
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
