import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftLintCoreMacros: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        AutoApply.self,
        MakeAcceptableByConfigurationElement.self,
        SwiftSyntaxRule.self
    ]
}
