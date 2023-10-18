import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct SwiftLintCoreMacros: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        AutoApply.self,
        MakeAcceptableByConfigurationElement.self,
        SwiftSyntaxRule.self
    ]
}

enum SwiftLintCoreMacroError: String, DiagnosticMessage {
    case notStruct = "Attribute can only be applied to structs"
    case notEnum = "Attribute can only be applied to enums"
    case noStringRawType = "Attribute can only be applied to enums with a 'String' raw type"

    var message: String {
        rawValue
    }

    var diagnosticID: MessageID {
        MessageID(domain: "SwiftLint", id: "SwiftLintCoreMacro.\(self)")
    }

    var severity: DiagnosticSeverity {
        .error
    }

    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }
}
