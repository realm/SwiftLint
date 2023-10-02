import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftLintCoreMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoApply.self,
        Fold.self,
        MakeAcceptableByConfigurationElement.self,
        SwiftSyntaxRule.self
    ]
}
