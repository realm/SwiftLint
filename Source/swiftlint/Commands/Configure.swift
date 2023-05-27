import ArgumentParser
import SwiftLintFramework
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension SwiftLint {
    struct Configure: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Configure SwiftLint")

        func run() throws {
            doYouWantToContinue("Welcome to SwiftLint! Do you want to continue? (Y/n)")
            ExitHelper.successfullyExit()
        }
    }
}

private func print(_ message: String, terminator: String = "\n") {
    Swift.print(message, terminator: terminator)
    fflush(stdout)
}

private func doYouWantToContinue(_ message: String) {
    print(message, terminator: " ")
}
