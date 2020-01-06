import Commandant
import Foundation
import SwiftLintFramework

struct GenerateDocsCommand: CommandProtocol {
    let verb = "generate-docs"
    let function = "Generates markdown documentation for all rules"

    func run(_ options: GenerateDocsOptions) -> Result<(), CommandantError<()>> {
        let docs = RuleListDocumentation(masterRuleList)
        do {
            try docs.write(to: URL(fileURLWithPath: options.path))
        } catch {
            return .failure(.usageError(description: error.localizedDescription))
        }

        return .success(())
    }
}

struct GenerateDocsOptions: OptionsProtocol {
    let path: String

    static func create(_ path: String) -> GenerateDocsOptions {
        return self.init(path: path)
    }

    static func evaluate(_ mode: CommandMode) -> Result<GenerateDocsOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| Option(key: "path", defaultValue: "rule_docs",
                               usage: "the directory where the documentation should be saved. defaults to `rule_docs`.")
    }
}
