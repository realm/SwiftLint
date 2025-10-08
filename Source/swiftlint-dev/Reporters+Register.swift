import ArgumentParser
import Foundation
import SwiftLintCore

extension SwiftLintDev.Reporters {
    struct Register: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "register",
            abstract: "Register reporters as provided by SwiftLint.",
            discussion: """
                This command registers reporters in the list of officially provided built-in reporters.
                """
        )

        private var reportersDirectory: URL {
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Source", isDirectory: true)
                .appendingPathComponent("SwiftLintFramework", isDirectory: true)
                .appendingPathComponent("Reporters", isDirectory: true)
        }

        func run() throws {
            guard FileManager.default.fileExists(atPath: reportersDirectory.path) else {
                throw ValidationError("Command must be run from the root of the SwiftLint repository.")
            }
            let reporters = try FileManager.default.contentsOfDirectory(
                    at: reportersDirectory,
                    includingPropertiesForKeys: nil
                )
                .map(\.lastPathComponent)
                .filter { $0.hasSuffix("Reporter.swift") && $0 != "Reporter.swift" }
                .sorted()
                .map { $0.replacingOccurrences(of: ".swift", with: ".self") }
                .joined(separator: ",\n")
            let builtInReportersFile = reportersDirectory.deletingLastPathComponent()
                .appendingPathComponent("Models", isDirectory: true)
                .appendingPathComponent("ReportersList.swift", isDirectory: false)
            try """
                // GENERATED FILE. DO NOT EDIT!

                /// The reporters list containing all the reporters built into SwiftLint.
                public let reportersList: [any Reporter.Type] = [
                \(reporters.indent(by: 4)),
                ]

                """.write(to: builtInReportersFile, atomically: true, encoding: .utf8)
        }
    }
}
