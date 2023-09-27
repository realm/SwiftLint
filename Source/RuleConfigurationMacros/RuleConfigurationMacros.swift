import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

@main
struct RuleConfigurationMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoApply.self,
        MakeAcceptableByConfigurationElement.self
    ]
}

private let configurationElementName = "ConfigurationElement"
private let acceptableByConfigurationElementName = "AcceptableByConfigurationElement"

private enum RuleConfigurationMacroError: DiagnosticMessage {
    case notStruct
    case notEnum
    case noStringRawType

    var message: String {
        switch self {
        case .notStruct:
            "Attribute can only be applied to structs"
        case .notEnum:
            "Attribute can only be applied to enums"
        case .noStringRawType:
            "Attribute can only be applied to enums with a 'String' raw type"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "SwiftLint", id: "AutoApply.\(self)")
    }

    var severity: DiagnosticSeverity {
        .error
    }

    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }
}

struct AutoApply: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let configuration = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(RuleConfigurationMacroError.notStruct.diagnose(at: declaration))
            return []
        }
        let elementsUpdate = configuration.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { varDecl in
                varDecl.attributes.contains { attr in
                    if let attrId = attr.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self) {
                        return attrId.name.text == configurationElementName
                    }
                    return false
                }
            }
            .compactMap { $0.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }
            .map {
                """
                try \($0).apply($\($0) == "" ? configuration : configuration[$\($0)], ruleID: Parent.identifier)
                """
            }
        return [
            """
            mutating func apply(configuration: Any) throws {
                guard let configuration = configuration as? [String: Any] else {
                    throw Issue.unknownConfiguration(ruleID: Parent.identifier)
                }
                \(raw: elementsUpdate.joined(separator: "\n"))
            }
            """
        ]
    }
}

struct MakeAcceptableByConfigurationElement: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(RuleConfigurationMacroError.notEnum.diagnose(at: declaration))
            return []
        }
        guard enumDecl.hasStringRawType else {
            context.diagnose(RuleConfigurationMacroError.noStringRawType.diagnose(at: declaration))
            return []
        }
        let accessLevel = enumDecl.accessLevel
        return [
            try ExtensionDeclSyntax("""
                extension \(type): \(raw: acceptableByConfigurationElementName) {
                    \(raw: accessLevel)func asOption() -> OptionType { .symbol(rawValue) }
                    \(raw: accessLevel)init(fromAny value: Any, context ruleID: String) throws {
                        if let value = value as? String, let newSelf = Self(rawValue: value) {
                            self = newSelf
                        } else {
                            throw Issue.unknownConfiguration(ruleID: ruleID)
                        }
                    }
                }
                """)
        ]
    }
}

private extension EnumDeclSyntax {
    var hasStringRawType: Bool {
        if let inheritanceClause {
            return inheritanceClause.inheritedTypes.contains {
                $0.type.as(IdentifierTypeSyntax.self)?.name.text == "String"
            }
        }
        return false
    }

    var accessLevel: String {
        modifiers.compactMap {
            switch $0.name.tokenKind {
            case .keyword(.public): "public "
            case .keyword(.package): "package "
            case .keyword(.private): "private "
            default: nil
            }
        }.first ?? ""
    }
}
