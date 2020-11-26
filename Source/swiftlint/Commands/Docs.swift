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
#if os(Linux)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
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
}
