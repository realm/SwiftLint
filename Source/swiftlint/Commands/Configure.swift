import ArgumentParser
import Foundation
import SwiftLintFramework
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension SwiftLint {
    struct Configure: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Configure SwiftLint")

        @Flag(help: "Colorize output regardless of terminal settings.")
        var colorize = false
        @Flag(help: "Do not colorize output regardless of terminal settings.")
        var noColorize = false

        private var shouldColorizeOutput: Bool {
            terminalSupportsColor() && (!noColorize || colorize)
        }

        func run() throws {
            doYouWantToContinue("Welcome to SwiftLint! Do you want to continue? (Y/n)")
            checkForExistingConfiguration()
            checkForExistingChildConfigurations()
            ExitHelper.successfullyExit()
        }

        private func checkForExistingConfiguration() {
            print("Checking for existing .swiftlint.yml configuration file.")
            if FileManager.default.fileExists(atPath: ".swiftlint.yml") {
                doYouWantToContinue("Found an existing .swiftlint.yml configuration file - do you want to continue? (Y/n)")
            }
        }

        private func checkForExistingChildConfigurations() {
            print("Checking for any other .swiftlint.yml configuration files.")
            let files = FileManager.default.filesMatching(".swiftlint.yml").filter { $0 != ".swiftlint.yml" }
            if files.isNotEmpty {
                print("Found existing child configurations:\n")
                files.forEach { print($0) }
                doYouWantToContinue("\nDo you want to continue? (Y/n)")
            }
        }

        private func doYouWantToContinue(_ message: String) {
            if !askUser(message, colorizeOutput: shouldColorizeOutput) {
                ExitHelper.successfullyExit()
            }
        }
    }
}

private func askUser(_ message: String, colorizeOutput: Bool) -> Bool {
    let colorizedMessage = colorizeOutput ? message.boldify : message
    while true {
        print(colorizedMessage, terminator: " ")
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
}

private extension FileManager {
    func filesMatching(_ fileName: String) -> [String] {
        var results: [String] = []
        let directoryEnumerator = enumerator(atPath: currentDirectoryPath)
        while let file = directoryEnumerator?.nextObject() as? String {
            if file.hasSuffix(".swiftlint.yml") {
                results.append(file)
            }
        }
        return results
    }
}
