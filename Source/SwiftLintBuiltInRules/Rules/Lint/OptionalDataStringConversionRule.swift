import SwiftSyntax
import Foundation

@SwiftSyntaxRule
struct OptionalDataStringConversionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    
    static let description = RuleDescription(
        identifier: "optional_data_string_conversion",
        name: "Optional Data -> String Conversion",
        description: "Prefer failable `String(bytes:encoding:)` initializer when converting `Data` to `String`",
        kind: .lint,
        nonTriggeringExamples: [
            Example("String(data: data, encoding: .utf8)"),
            Example("String(bytes: data, encoding: .utf8)"),
            Example("String(UTF8.self)"),
            Example("String(a, b, c, UTF8.self)"),
            Example("String(decoding: data, encoding: UTF8.self)"),
        ],
        triggeringExamples: [
            Example("String(decoding: data, as: UTF8.self)"),
            Example("String.init(decoding: data, as: UTF8.self)"),
            Example("let text: String = .init(decoding: data, as: UTF8.self)"),
        ]
    )
}

private extension OptionalDataStringConversionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclReferenceExprSyntax) {
            if node.baseName.text == "String",
               let parent = node.parent?.as(FunctionCallExprSyntax.self),
               parent.arguments.map(\.label?.text) == ["decoding", "as"],
               let expr = parent.arguments.last?.expression.as(MemberAccessExprSyntax.self),
               expr.base?.description == "UTF8",
               expr.declName.baseName.description == "self" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            // Matches String.init(...) and .init(...) used with a variable typed as String
            guard node.declName.baseName.text == "init" else { return }
            
            // Helper to validate the function-call shape and UTF8.self argument
            func parentCallLooksLikeDecodingAsUTF8(_ parentCall: FunctionCallExprSyntax?) -> Bool {
                guard let parent = parentCall else { return false }
                guard parent.arguments.map(\.label?.text) == ["decoding", "as"] else { return false }
                guard let expr = parent.arguments.last?.expression.as(MemberAccessExprSyntax.self) else { return false }
                return expr.base?.description == "UTF8" && expr.declName.baseName.description == "self"
            }
            
            // Case 1: String.init(decoding:as:)
            if let base = node.base?.as(DeclReferenceExprSyntax.self),
               base.baseName.text == "String",
               parentCallLooksLikeDecodingAsUTF8(node.parent?.as(FunctionCallExprSyntax.self)) {
                violations.append(node.positionAfterSkippingLeadingTrivia)
                return
            }
            
            // Case 2: .init(decoding:as:) where the type is provided by an explicit variable type annotation
            // Walk up ancestors to find a VariableDecl or PatternBinding with a type annotation of `String`
            if node.base == nil, // leading-dot init: `.init(...)`
               parentCallLooksLikeDecodingAsUTF8(node.parent?.as(FunctionCallExprSyntax.self)) {
                var ancestor: Syntax? = node.parent
                while let a = ancestor {
                    if let varDecl = a.as(VariableDeclSyntax.self) {
                        // Check all bindings for a type annotation equal to `String`
                        if varDecl.bindings.contains(where: { binding in
                            binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "String"
                        }) {
                            violations.append(node.positionAfterSkippingLeadingTrivia)
                            return
                        }
                    }
                    
                    if let patternBinding = a.as(PatternBindingSyntax.self),
                       patternBinding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "String" {
                        violations.append(node.positionAfterSkippingLeadingTrivia)
                        return
                    }
                    
                    ancestor = a.parent
                }
            }
        }
    }
}
