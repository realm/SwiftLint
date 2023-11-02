import ArgumentParser
import Foundation

extension SwiftLint {
    struct Dev: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Open an Xcode project to develop custom native rules"
        )

        func run() throws {
            xed(pluginPackageManifestURL())
            ExitHelper.successfullyExit()
        }
    }
}

private func xed(_ url: URL) {
    let process = Process()
    process.launchPath = "/usr/bin/xed"
    process.arguments = [url.path]
    process.launch()
}
