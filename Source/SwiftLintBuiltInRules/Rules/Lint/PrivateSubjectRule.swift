import SwiftSyntax

struct PrivateSubjectRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    // MARK: - Properties

    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "private_subject",
        name: "Private Combine Subject",
        description: "Combine Subject should be private",
        kind: .lint,
        nonTriggeringExamples: PrivateSubjectRuleExamples.nonTriggeringExamples,
        triggeringExamples: PrivateSubjectRuleExamples.triggeringExamples
    )

    // MARK: - Life cycle

    init() {}

    // MARK: - Public

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension PrivateSubjectRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let subjectTypes: Set<String> = ["PassthroughSubject", "CurrentValueSubject"]

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            [FunctionDeclSyntax.self, VariableDeclSyntax.self, SubscriptDeclSyntax.self]
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard !node.modifiers.isPrivateOrFileprivate,
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
                if let type = binding.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self),
                   subjectTypes.contains(type.name.text) {
                    violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
                    continue
                }

                // Looks for violations matching the format:
                //
                // * `let subject = PassthroughSubject<Bool, Never>()`
                // * `let subject = CurrentValueSubject<String, Never>("toto")`
                if let functionCall = binding.initializer?.value.as(FunctionCallExprSyntax.self),
                   let specializeExpr = functionCall.calledExpression.as(SpecializeExprSyntax.self),
                   let identifierExpr = specializeExpr.expression.as(IdentifierExprSyntax.self),
                   subjectTypes.contains(identifierExpr.identifier.text) {
                    violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }
}
