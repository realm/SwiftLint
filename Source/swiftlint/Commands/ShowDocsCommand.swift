import Commandant
import Foundation

struct ShowDocsCommand: CommandProtocol {
    let verb = "docs"
    let function = "Open SwiftLint Docs on web browser"

    func run(_ options: NoOptions<CommandantError<()>>) -> Result<(), CommandantError<()>> {
        let url = URL(string: "https://realm.github.io/SwiftLint")!
        open(url)
        return .success(())
    }
}

private extension ShowDocsCommand {
    func open(_ url: URL) {
        let process = Process()
        let envPath = "/usr/bin/env"

#if os(macOS)
        process.launchPath = envPath
        process.arguments = ["open", url.absoluteString]
        process.launch()
#else
        process.executableURL = URL(fileURLWithPath: envPath)
        process.arguments = ["xdg-open", url.absoluteString]
        process.run()
#endif
    }
}
