import ArgumentParser
import Foundation

extension SwiftLint {
    struct Docs: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Open SwiftLint documentation website in the default web browser"
        )

        func run() throws {
            open(URL(string: "https://realm.github.io/SwiftLint")!)
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
