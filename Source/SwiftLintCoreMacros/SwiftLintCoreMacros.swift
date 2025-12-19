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
        TemporaryDirectory.self,
        WorkingDirectory.self,
    ]
}

#if os(Windows)
@_cdecl("main")
public func main() {
    try! SwiftLintCoreMacros.main()
}
#endif
