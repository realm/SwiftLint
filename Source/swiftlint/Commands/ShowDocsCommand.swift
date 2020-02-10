import Commandant
import Foundation

struct ShowDocsCommand: CommandProtocol {
    let verb = "show-docs"
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
        process.launchPath = "/usr/bin/env"
        let command: String = {
            #if os(Linux)
            return "xdg-open"
            #else
            return "open"
            #endif
        }()
        process.arguments = [command, url.absoluteString]
        process.launch()
    }
}
