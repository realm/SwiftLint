import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct SwiftLintCoreMacros: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        AutoConfigParser.self,
        AcceptableByConfigurationElement.self,
        SwiftSyntaxRule.self,
    ]
}

enum SwiftLintCoreMacroError: String, DiagnosticMessage {
    case notStruct = "Attribute can only be applied to structs"
    case severityBasedWithoutProperty = """
        Severity-based configuration without a 'severityConfiguration' property is invalid
        """
    case notEnum = "Attribute can only be applied to enums"
    case noStringRawType = "Attribute can only be applied to enums with a 'String' raw type"
    case noBooleanLiteral = "Macro argument must be a boolean literal"

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
