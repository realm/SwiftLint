import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct SwiftLintCoreMacros: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        AutoConfigParser.self,
        AcceptableByConfigurationElement.self,
        DisabledWithoutSourceKit.self,
        SwiftSyntaxRule.self,
    ]
}
