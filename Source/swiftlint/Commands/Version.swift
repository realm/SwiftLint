import ArgumentParser
import SwiftLintFramework

extension SwiftLint {
    struct Version: ParsableCommand {
        @Flag(help: "Display full version info")
        var verbose = false

        static let configuration = CommandConfiguration(abstract: "Display the current version of SwiftLint")

        static var value: String { SwiftLintFramework.Version.current.value }

        func run() throws {
            if verbose, let buildID = ExecutableInfo.buildID {
                print("Version:", Self.value)
                print("Build ID:", buildID)
            } else {
                print(Self.value)
            }
        }
    }
}
