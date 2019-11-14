import Commandant
import SwiftLintFramework

struct GenerateDocsCommand: CommandProtocol {
    let verb = "generate-docs"
    let function = "Generates markdown documentation for all rules"

    func run(_ options: GenerateDocsOptions) -> Result<(), CommandantError<()>> {

        if options.onlyDisabledRules && options.onlyEnabledRules {
            return .failure(.usageError(description: "You can't use --disabled and --enabled at the same time."))
        }

        let text = ruleList(for: options)
            .generateDocumentation()

        if let path = options.path {
            do {
                try text.write(toFile: path, atomically: true, encoding: .utf8)
            } catch {
                return .failure(.usageError(description: error.localizedDescription))
            }
        } else {
            queuedPrint(text)
        }

        return .success(())
    }
}

private extension GenerateDocsCommand {
    func ruleList(for options: GenerateDocsOptions) -> RuleList {
        guard options.onlyDisabledRules || options.onlyEnabledRules else { return masterRuleList }
        fatalError("Not implemented")
    }
}

struct GenerateDocsOptions: OptionsProtocol {
    let configurationFile: String
    let path: String?
    let onlyEnabledRules: Bool
    let onlyDisabledRules: Bool

    static func create(_ configurationFile: String) -> (_ path: String?) -> (_ onlyEnabledRules: Bool) -> (_ onlyDisabledRules: Bool) -> GenerateDocsOptions {
        return { path in { onlyEnabledRules in { onlyDisabledRules in
            self.init(configurationFile: configurationFile,
                      path: path,
                      onlyEnabledRules: onlyEnabledRules,
                      onlyDisabledRules: onlyDisabledRules)
                }
            }
        }
    }

    static func evaluate(_ mode: CommandMode) -> Result<GenerateDocsOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| configOption
            <*> mode <| Option(key: "path", defaultValue: nil,
                               usage: "the path where the documentation should be saved. " +
                                      "If not present, it'll be printed to the output.")
            <*> mode <| Switch(flag: "e",
                               key: "enabled",
                               usage: "only print enabled rules")
            <*> mode <| Switch(flag: "d",
                               key: "disabled",
                               usage: "only print disabled rules")
    }
}
