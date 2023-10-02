import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftLintCoreMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoApply.self,
        MakeAcceptableByConfigurationElement.self
    ]
}
