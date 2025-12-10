import Foundation
import SwiftSyntax

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
            // Additional non-triggering examples to maximize coverage:
            Example("String(data: data, encoding: .ascii)"),
            Example("String(bytes: data, encoding: .utf16LittleEndian)"),
            Example("String(decoding: data, as: UTF16.self)"),
            Example("String.init(bytes: data, encoding: .utf8)"),
            Example("let text: String = .init(bytes: data, encoding: .utf8)"),
            Example("let text: String = .init(data)"),
            Example("let text: Int = .init(decoding: data, as: UTF8.self)"),
            Example("let n: Int = .init(0)"),
            Example("String(repeating: \"a\", count: 3)"),
            Example("String(format: \"%d\", 3)"),
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
        override func visitPost(_ node: FunctionCallExprSyntax) {
            // Only consider calls with labels `decoding` and `as`
            guard node.arguments.map(\.label?.text) == ["decoding", "as"] else { return }
            // Check that the `as:` argument is `UTF8.self`
            guard let lastExpr = node.arguments.last?.expression.as(MemberAccessExprSyntax.self),
                  lastExpr.base?.description == "UTF8",
                  lastExpr.declName.baseName.description == "self" else { return }

            // Called expression can be:
            // 1) DeclReferenceExprSyntax("String") -> String(decoding:as:)
            // 2) MemberAccessExprSyntax(base: DeclReferenceExprSyntax("String"), declName: "init") -> String.init(...)
            // 3) MemberAccessExprSyntax(base: nil, declName: "init") -> .init(...) (leading-dot)
            let called = node.calledExpression

            // Case 1: direct `String(...)`
            if let declRef = called.as(DeclReferenceExprSyntax.self), declRef.baseName.text == "String" {
                violations.append(called.positionAfterSkippingLeadingTrivia)
                return
            }

            // Case 2 and 3: `.init` or `String.init`
            guard let member = called.as(MemberAccessExprSyntax.self),
                  member.declName.baseName.text == "init" else { return }

            // Case 2: `String.init(...)`
            if let baseDecl = member.base?.as(DeclReferenceExprSyntax.self),
               baseDecl.baseName.text == "String" {
                violations.append(called.positionAfterSkippingLeadingTrivia)
                return
            }

            // Case 3: leading-dot `.init(...)`
            // This is ambiguous in general. We conservatively only trigger if the call
            // is used to initialize a variable that has an explicit `String` type annotation:
            // let x: String = .init(...)
            // We intentionally do not (yet) match arbitrary contexts like f(.init(...)) or returns,
            // because `.init` can refer to other types and those cases are frequent and risky.
            guard member.base == nil else { return }

            // Walk ancestors to find a VariableDecl or PatternBinding with a type annotation of `String`.
            if let binding = node.parent?.parent?.as(PatternBindingSyntax.self),
               binding.typeAnnotation?.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines) == "String" {
                violations.append(called.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
