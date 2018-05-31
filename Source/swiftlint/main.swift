import Commandant
import Dispatch
import Foundation
import SwiftLintFramework

DispatchQueue.global().async {
    let registry = CommandRegistry<CommandantError<()>>()
    registry.register(LintCommand())
    registry.register(AutoCorrectCommand())
    registry.register(VersionCommand())
    registry.register(RulesCommand())
    registry.register(GenerateDocsCommand())
    registry.register(HelpCommand(registry: registry))

    registry.main(defaultVerb: LintCommand().verb) { error in
        queuedPrintError(String(describing: error))
    }
}

dispatchMain()
