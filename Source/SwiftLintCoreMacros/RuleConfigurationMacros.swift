import Foundation
import SwiftBasicFormat
import SwiftSyntaxBuilder
import SwiftSyntax
import SwiftSyntaxMacros

enum AutoApply: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let configuration = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(SwiftLintCoreMacroError.notStruct.diagnose(at: declaration))
            return []
        }
        let elementNames = configuration.memberBlock.members
            .compactMap {
                if let varDecl = $0.decl.as(VariableDeclSyntax.self),
                   varDecl.configurationElementAnnotation != nil {
                    return varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                }
                return nil
            }
        let inlinedOptionsUpdate = elementNames.map {
            """
            if $\($0).inline {
                inlinableOptionsExist = true
                try \($0).apply(configuration, ruleID: Parent.identifier)
                try $\($0).performAfterParseOperations()
            }
            """
        }
        let nonInlinedOptionsUpdate = elementNames.map {
            """
            if !$\($0).inline {
                if $\($0).key.isEmpty {
                    $\($0).key = "\($0.snakeCased)"
                }
                try \($0).apply(configuration[$\($0).key], ruleID: Parent.identifier)
                try $\($0).performAfterParseOperations()
            }
            """
        }
        return [
            """
            mutating func apply(configuration: Any) throws {
                var inlinableOptionsExist = false
                \(raw: inlinedOptionsUpdate.joined())
                guard let configuration = configuration as? [String: Any] else {
                    if inlinableOptionsExist {
                        return
                    } else {
                        throw Issue.invalidConfiguration(ruleID: Parent.description.identifier)
                    }
                }
                \(raw: nonInlinedOptionsUpdate.joined())
                if !supportedKeys.isSuperset(of: configuration.keys) {
                    let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                    throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                }
            }
            """
        ]
    }
}

enum MakeAcceptableByConfigurationElement: ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(SwiftLintCoreMacroError.notEnum.diagnose(at: declaration))
            return []
        }
        guard enumDecl.hasStringRawType else {
            context.diagnose(SwiftLintCoreMacroError.noStringRawType.diagnose(at: declaration))
            return []
        }
        let accessLevel = enumDecl.accessLevel
        return [
            try ExtensionDeclSyntax("""
                extension \(type): AcceptableByConfigurationElement {
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

private extension VariableDeclSyntax {
    var configurationElementAnnotation: AttributeSyntax? {
        let attribute = attributes.first {
            if let attr = $0.as(AttributeSyntax.self), let attrId = attr.attributeName.as(IdentifierTypeSyntax.self) {
                return attrId.name.text == "ConfigurationElement"
            }
            return false
        }
        return if case let .attribute(unwrapped) = attribute { unwrapped } else { nil }
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

private extension String {
    // swiftlint:disable:next force_try
    static let regex = try! NSRegularExpression(pattern: "(?<!^)(?=[A-Z])")

    var snakeCased: Self {
        Self.regex.stringByReplacingMatches(
            in: self,
            range: NSRange(location: 0, length: utf16.count),
            withTemplate: "_"
        ).lowercased()
    }
}
