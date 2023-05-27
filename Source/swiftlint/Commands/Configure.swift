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
        var colorizeOutput = false
        @Flag(help: "Do not colorize output regardless of terminal settings.")
        var noColorizeOutput = false

        private lazy var shouldColorizeOutput: Bool = {
            terminalSupportsColor() && (!noColorizeOutput || colorizeOutput)
        }()

        func run() throws {
            doYouWantToContinue("Welcome to SwiftLint! Do you want to continue? (Y/n)")
            ExitHelper.successfullyExit()
        }

        private func doYouWantToContinue(_ message: String) {
            if !askUser(message) {
                ExitHelper.successfullyExit()
            }
        }

        private func askUser(_ message: String) -> Bool {
            // let colorizeOutput = shouldColorizeOutput
            let colorizedMessage = true ? message.boldify : message
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
        "\u{001B}[0;1m\(self)"
    }
}
