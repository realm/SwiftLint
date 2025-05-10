import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PrivateSubjectRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "private_subject",
        name: "Private Combine Subject",
        description: "Combine Subject should be private",
        kind: .lint,
        nonTriggeringExamples: PrivateSubjectRuleExamples.nonTriggeringExamples,
        triggeringExamples: PrivateSubjectRuleExamples.triggeringExamples
    )
}

private extension PrivateSubjectRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private let subjectTypes: Set<String> = ["PassthroughSubject", "CurrentValueSubject"]

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [FunctionDeclSyntax.self, VariableDeclSyntax.self, SubscriptDeclSyntax.self, InitializerDeclSyntax.self]
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard !node.modifiers.containsPrivateOrFileprivate(),
                  !node.modifiers.containsStaticOrClass else {
                return
            }

            for binding in node.bindings {
                // Looks for violations matching the format:
                //
                // * `let subject: PassthroughSubject<Bool, Never>`
                // * `let subject: PassthroughSubject<Bool, Never> = .init()`
                // * `let subject: CurrentValueSubject<Bool, Never>`
                // * `let subject: CurrentValueSubject<String, Never> = .init("toto")`
                if let type = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self),
                   subjectTypes.contains(type.name.text) {
                    violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
                    continue
                }

                // Looks for violations matching the format:
                //
                // * `let subject = PassthroughSubject<Bool, Never>()`
                // * `let subject = CurrentValueSubject<String, Never>("toto")`
                if let functionCall = binding.initializer?.value.as(FunctionCallExprSyntax.self),
                   let specializeExpr = functionCall.calledExpression.as(GenericSpecializationExprSyntax.self),
                   let identifierExpr = specializeExpr.expression.as(DeclReferenceExprSyntax.self),
                   subjectTypes.contains(identifierExpr.baseName.text) {
                    violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}
