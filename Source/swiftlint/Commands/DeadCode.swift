import ArgumentParser
import Foundation
import SwiftLintAnalyzerRules
import SwiftLintFramework

extension SwiftLint {
    struct DeadCode: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Detect dead code (experimental)")

        @Option(help: "The path on disk to the index store directory.")
        var indexStorePath: String

        func run() async throws {
            let start = Date()

            let allUnused = try await UnusedDeclarationFinder.find(
                indexStorePath: indexStorePath
            )

            let output = allUnused
                .map(\.logDescription)
                .joined(separator: "\n")

            if !output.isEmpty {
                print(output)
            }

            let duration = String(format: "%.2fs", -start.timeIntervalSinceNow)
            print("Found \(allUnused.count) unused declarations (\(duration))")

            if !output.isEmpty {
                throw ExitCode.failure
            }

            ExitHelper.successfullyExit()
        }
    }
}
