import Foundation
import Yams

private struct SwiftPMCommand: Codable {
    let tool: String
    let module: String?
    let sources: [String]?
    let args: [String]?
    let importPaths: [String]?

    enum CodingKeys: String, CodingKey {
        case tool
        case module = "module-name"
        case sources
        case args = "other-args"
        case importPaths = "import-paths"
    }
}

private struct SwiftPMNode: Codable {}

private struct SwiftPMNodes: Codable {
    let nodes: [String: SwiftPMNode]
}

struct SwiftPMCompilationDB: Codable {
    private let commands: [String: SwiftPMCommand]

    static func parse(yaml: Data) throws -> [File: Arguments] {
        let decoder = YAMLDecoder()
        let compilationDB: SwiftPMCompilationDB

        if ProcessInfo.processInfo.environment["TEST_SRCDIR"] != nil {
            // Running tests
            let nodes = try decoder.decode(SwiftPMNodes.self, from: yaml)
            let suffix = "/Source/swiftlint/"
            let pathToReplace = Array(nodes.nodes.keys.filter({ node in
                node.hasSuffix(suffix)
            }))[0].dropLast(suffix.count - 1)
            let stringFileContents = String(data: yaml, encoding: .utf8)!
                .replacingOccurrences(of: pathToReplace, with: "")
            compilationDB = try decoder.decode(Self.self, from: stringFileContents)
        } else {
            compilationDB = try decoder.decode(Self.self, from: yaml)
        }

        let swiftCompilerCommands = compilationDB.commands
            .filter { $0.value.tool == "swift-compiler" }
        let allSwiftSources = swiftCompilerCommands
            .flatMap { $0.value.sources ?? [] }
            .filter { $0.hasSuffix(".swift") }
        return Dictionary(uniqueKeysWithValues: allSwiftSources.map { swiftSource in
            let command = swiftCompilerCommands
                .values
                .first { $0.sources?.contains(swiftSource) == true }

            guard let command,
                  let module = command.module,
                  let sources = command.sources,
                  let arguments = command.args,
                  let importPaths = command.importPaths
            else {
                return (swiftSource, [])
            }

            let args = ["-module-name", module] +
                sources +
                arguments.filteringCompilerArguments +
                ["-I"] + importPaths

            return (swiftSource, args)
        })
    }
}
