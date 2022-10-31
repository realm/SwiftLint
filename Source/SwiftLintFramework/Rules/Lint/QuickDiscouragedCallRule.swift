import SwiftSyntax

public struct QuickDiscouragedCallRule: OptInRule, SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_discouraged_call",
        name: "Quick Discouraged Call",
        description: "Discouraged call inside 'describe' and/or 'context' block.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedCallRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedCallRuleExamples.triggeringExamples
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension QuickDiscouragedCallRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            .all
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            guard let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
                  case let name = identifierExpr.identifier.text,
                  let kind = QuickCallKind(rawValue: name),
                  QuickCallKind.restrictiveKinds.contains(kind) else {
                return .skipChildren
            }

            let functionViolations = FunctionCallVisitor(nameToReport: name)
                .walk(tree: node, handler: \.violations)
            violations.append(contentsOf: functionViolations.unique)
            return .skipChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            node.containsInheritance ? .visitChildren : .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            node.isQuickSpecFunction ? .visitChildren : .skipChildren
        }
    }

    private class FunctionCallVisitor: ViolationsSyntaxVisitor {
        private let nameToReport: String

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            .allExcept(VariableDeclSyntax.self)
        }

        init(nameToReport: String) {
            self.nameToReport = nameToReport
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            let hasViolation: Bool

            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self) {
                let name = identifierExpr.identifier.text
                if let kind = QuickCallKind(rawValue: name), QuickCallKind.restrictiveKinds.contains(kind) {
                    return .visitChildren
                }

                hasViolation = QuickCallKind(rawValue: name) == nil
            } else {
                hasViolation = true
            }

            if hasViolation {
                violations.append(
                    ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: "Discouraged call inside a '\(nameToReport)' block."
                    )
                )
            }

            return .skipChildren
        }
    }
}

private enum QuickCallKind: String {
    case describe
    case context
    case sharedExamples
    case itBehavesLike
    case aroundEach
    case beforeEach
    case beforeSuite
    case afterEach
    case afterSuite
    case it // swiftlint:disable:this identifier_name
    case pending
    case xdescribe
    case xcontext
    case xit
    case xitBehavesLike
    case fdescribe
    case fcontext
    case fit
    case fitBehavesLike

    static let restrictiveKinds: Set<QuickCallKind> = [
        .describe, .fdescribe, .xdescribe, .context, .fcontext, .xcontext, .sharedExamples
    ]
}
