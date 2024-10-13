import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum AutoConfigParser: MemberMacro {
    // swiftlint:disable:next function_body_length
    static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let configuration = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(SwiftLintCoreMacroError.notStruct.diagnose(at: declaration))
            return []
        }
        var annotatedVarDecls = configuration.memberBlock.members
            .compactMap {
                if let varDecl = $0.decl.as(VariableDeclSyntax.self),
                   let annotation = varDecl.configurationElementAnnotation {
                    return (varDecl, annotation)
                }
                return nil
            }
        let firstIndexWithoutKey = annotatedVarDecls
            .partition { _, annotation in
                if case let .argumentList(arguments) = annotation.arguments {
                    return arguments.contains {
                           $0.label?.text == "inline"
                        && $0.expression.as(BooleanLiteralExprSyntax.self)?.literal.text == "true"
                    }
                }
                return false
            }
        let elementNames = annotatedVarDecls.compactMap {
            $0.0.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }
        let nonInlinedOptions = elementNames[..<firstIndexWithoutKey]
        var inlinedOptions = elementNames[firstIndexWithoutKey...]
        let isSeverityBased = configuration.inheritanceClause?.inheritedTypes.contains {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text == "SeverityBasedRuleConfiguration"
        }
        if isSeverityBased == true {
            if nonInlinedOptions.contains("severityConfiguration") {
                inlinedOptions.append("severityConfiguration")
            } else {
                context.diagnose(SwiftLintCoreMacroError.severityBasedWithoutProperty.diagnose(at: configuration.name))
            }
        }
        return [
            DeclSyntax(try FunctionDeclSyntax("mutating func apply(configuration: Any) throws") {
                for option in nonInlinedOptions {
                    """
                    if $\(raw: option).key.isEmpty {
                        $\(raw: option).key = "\(raw: option.snakeCased)"
                    }
                    """
                }
                for option in inlinedOptions {
                    """
                    do {
                        try \(raw: option).apply(configuration, ruleID: Parent.identifier)
                    } catch let issue as Issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
                        // Acceptable. Continue.
                    }
                    """
                }
                """
                guard let configuration = configuration as? [String: Any] else {
                    \(raw: inlinedOptions.isEmpty
                        ? "throw Issue.invalidConfiguration(ruleID: Parent.identifier)"
                        : "return")
                }
                """
                for option in nonInlinedOptions {
                    """
                    if let value = configuration[$\(raw: option).key] {
                        try \(raw: option).apply(value, ruleID: Parent.identifier)
                    }
                    """
                }
                """
                if !supportedKeys.isSuperset(of: configuration.keys) {
                    let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                    Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
                }
                """
                """
                try validate()
                """
            }),
        ]
    }
}

enum AcceptableByConfigurationElement: ExtensionMacro {
    static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
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
                            throw Issue.invalidConfiguration(ruleID: ruleID)
                        }
                    }
                }
                """),
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
