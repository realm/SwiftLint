import Commandant
import Dispatch
import SwiftLintFramework

// TODO: Remove me. Force CI to run OSSCheck and trigger a lint failure.

DispatchQueue.global().async {
    let registry = CommandRegistry<CommandantError<()>>()
    registry.register(LintCommand())
    registry.register(AutoCorrectCommand())
    registry.register(AnalyzeCommand())
    registry.register(VersionCommand())
    registry.register(RulesCommand())
    registry.register(GenerateDocsCommand())
    registry.register(HelpCommand(registry: registry))

    registry.main(defaultVerb: LintCommand().verb) { error in
        queuedPrintError(String(describing: error))
    }
}

dispatchMain()
