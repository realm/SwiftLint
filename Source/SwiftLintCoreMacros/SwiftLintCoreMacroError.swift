import SwiftDiagnostics
import SwiftSyntax

enum SwiftLintCoreMacroError: String, DiagnosticMessage {
    case notStruct = "Attribute can only be applied to structs"
    case invalidConfigurationName = "Configuration type name must end with 'Configuration', but not 'RuleConfiguration'"
    case severityBasedWithoutProperty = """
        Severity-based configuration without a 'severityConfiguration' property is invalid
        """
    case notEnum = "Attribute can only be applied to enums"
    case noStringRawType = "Attribute can only be applied to enums with a 'String' raw type"
    case noBooleanLiteral = "Macro argument must be a boolean literal"
    case noBody = "Macro can only be applied to functions with a body"
    case missingPathArgument = "Missing required 'path' argument"

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
