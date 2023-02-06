import ArgumentParser
import Foundation
import SwiftLintFramework

extension SwiftLint {
    struct Docs: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Open SwiftLint documentation website in the default web browser"
        )

        @Argument(help: "The identifier of the rule to open the documentation for")
        var ruleID: String?

        func run() throws {
            var subPage = ""
            if let ruleID {
                if primaryRuleList.list[ruleID] == nil {
                    queuedPrintError("There is no rule named '\(ruleID)'. Opening rule directory instead.")
                    subPage = "rule-directory.html"
                } else {
                    subPage = ruleID + ".html"
                }
            }
            open(URL(string: "https://realm.github.io/SwiftLint/\(subPage)")!)
            ExitHelper.successfullyExit()
        }
    }
}

private func open(_ url: URL) {
    let process = Process()
#if os(Linux)
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env", isDirectory: false)
    let command = "xdg-open"
    process.arguments = [command, url.absoluteString]
    try? process.run()
#else
    process.launchPath = "/usr/bin/env"
    let command = "open"
    process.arguments = [command, url.absoluteString]
    process.launch()
#endif
}
