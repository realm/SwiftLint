import ArgumentParser
import SwiftLintFramework

extension SwiftLint {
    struct Version: AsyncParsableCommand {
        @Flag(help: "Display full version info.")
        var verbose = false
        @Flag(help: "Check whether a later version of SwiftLint is available after processing all files.")
        var checkForUpdates = false

        static let configuration = CommandConfiguration(abstract: "Display the current version of SwiftLint")

        static var value: String { SwiftLintFramework.Version.current.value }

        func run() async {
            if verbose, let buildID = ExecutableInfo.buildID {
                print("Version:", Self.value)
                print("Build ID:", buildID)
            } else {
                print(Self.value)
            }
            if checkForUpdates {
                await UpdateChecker.checkForUpdates()
            }
        }
    }
}
