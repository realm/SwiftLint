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

struct SwiftPMCompilationDB: Codable {
    private let commands: [String: SwiftPMCommand]

    static func parse(yaml: Data) throws -> [File: Arguments] {
        let decoder = YAMLDecoder()
        let compilationDB = try decoder.decode(Self.self, from: yaml)

        let swiftCompilerCommands = compilationDB.commands
            .filter { $0.value.tool == "swift-compiler" }
        let allSwiftSources = swiftCompilerCommands
            .flatMap { $0.value.sources ?? [] }
            .filter { $0.hasSuffix(".swift") }
        return Dictionary(uniqueKeysWithValues: allSwiftSources.map { swiftSource in
            let command = swiftCompilerCommands
                .values
                .first { $0.sources?.contains(swiftSource) == true }

            guard let command = command,
                  let module = command.module,
                  let sources = command.sources,
                    let arguments = command.args else {
                return (swiftSource, [])
            }

            let importPathsArguments = (command.importPaths ?? [])
                .flatMap { ["-I", $0] }

            let args = ["-module-name", module] +
                sources +
                arguments.filteringCompilerArguments +
                importPathsArguments

            return (swiftSource, args)
        })
    }
}
