import ArgumentParser
import SwiftLintFramework

extension SwiftLint {
    struct Version: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Display the current version of SwiftLint")

        static var value: String { SwiftLintFramework.Version.current.value }

        mutating func run() throws {
            print(Self.value)
        }
    }
}
