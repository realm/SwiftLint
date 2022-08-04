import ArgumentParser
import Foundation

extension SwiftLint {
    struct ParseOSSCheckResults: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Parse OSSCheck results"
        )

        @Option(help: "The path to the log file")
        var logs: String?

        mutating func run() throws {
            let lines = try String(contentsOfFile: logs!)
                .components(separatedBy: "\n")

            let fixed = lines.filter { line in
                line.contains("This PR fixed a violation")
            }.map { $0.ossCheckProcessed() }

            let introduced = lines.filter { line in
                line.contains("This PR introduced a violation")
            }.map { $0.ossCheckProcessed() }

            let removed = fixed.filter { !introduced.contains($0) }
            let added = introduced.filter { !fixed.contains($0) }

            print("\(removed.count) removed and \(added.count) added")
            print("## Removed")
            print(removed.map({ "* \($0)" }).joined(separator: "\n"))
            print("## Added")
            print(added.map({ "* \($0)" }).joined(separator: "\n"))
        }
    }
}

extension String {
    func ossCheckProcessed() -> String {
        ("https://github.com/" + components(separatedBy: "github.com/")[1].components(separatedBy: ":")[0])
            .replacingOccurrences(of: " ", with: "%20")
    }
}
