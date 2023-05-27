import ArgumentParser
import SwiftLintFramework

extension SwiftLint {
    struct Configure: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Configure SwiftLint")

        func run() throws {
            print("Hello")
            ExitHelper.successfullyExit()
        }
    }
}
