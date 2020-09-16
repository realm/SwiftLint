import Commandant
import Dispatch
import SwiftLintFramework

// Touch

DispatchQueue.global().async {
    let registry = CommandRegistry<CommandantError<()>>()
    registry.register(LintCommand())
    registry.register(AutoCorrectCommand())
    registry.register(AnalyzeCommand())
    registry.register(VersionCommand())
    registry.register(RulesCommand())
    registry.register(GenerateDocsCommand())
    registry.register(ShowDocsCommand())
    registry.register(HelpCommand(registry: registry))

    registry.main(defaultVerb: LintCommand().verb) { error in
        queuedPrintError(String(describing: error))
    }
}

dispatchMain()
