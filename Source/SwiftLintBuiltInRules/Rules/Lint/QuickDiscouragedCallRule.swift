import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct QuickDiscouragedCallRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "quick_discouraged_call",
        name: "Quick Discouraged Call",
        description: "Discouraged call inside 'describe' and/or 'context' block.",
        kind: .lint,
        nonTriggeringExamples: QuickDiscouragedCallRuleExamples.nonTriggeringExamples,
        triggeringExamples: QuickDiscouragedCallRuleExamples.triggeringExamples
    )
}

private typealias ScopeElement = (kind: QuickCallKind, blockId: SyntaxIdentifier)?

private extension QuickDiscouragedCallRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var quickScope = Stack<ScopeElement>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            .allExcept(ClassDeclSyntax.self, FunctionDeclSyntax.self, VariableDeclSyntax.self)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause?.inheritedTypes.isNotEmpty == true {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.name.text == "spec",
               node.signature.parameterClause.parameters.isEmpty,
               node.signature.returnClause == nil {
                return .visitChildren
            }
            return .skipChildren
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if let calledName = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text {
                if let kind = QuickCallKind(rawValue: calledName) {
                    if let closure = node.trailingClosure {
                        quickScope.push((kind, closure.statements.id))
                        return .visitChildren
                    }
                    quickScope.push(nil)
                    return .skipChildren
                }
            }
            if let scope = quickScope.lastSuspiciousScope(node) {
                violations.append(.violation(at: node.positionAfterSkippingLeadingTrivia, kind: scope.kind))
                return .skipChildren
            }
            quickScope.push(nil)
            return .visitChildren
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            for binding in node.bindings {
                if let scope = quickScope.lastSuspiciousScope(node),
                   let initializer = binding.initializer,
                   FunctionCallFinder(viewMode: .sourceAccurate).walk(tree: initializer.value, handler: \.found) {
                    violations.append(.violation(
                        at: initializer.value.positionAfterSkippingLeadingTrivia,
                        kind: scope.kind
                    ))
                }
            }
            return .skipChildren
        }

        override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
            guard let scope = quickScope.lastSuspiciousScope(node),
                  node.operator.is(AssignmentExprSyntax.self),
                  node.leftOperand.is(DeclReferenceExprSyntax.self) || node.leftOperand.is(MemberAccessExprSyntax.self),
                  let call = node.rightOperand.as(FunctionCallExprSyntax.self) else {
                return .visitChildren
            }
            violations.append(.violation(at: call.positionAfterSkippingLeadingTrivia, kind: scope.kind))
            return .skipChildren
        }

        override func visitPost(_: FunctionCallExprSyntax) {
            quickScope.pop()
        }

        override func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
            if let elements = node.elements?.as(CodeBlockItemListSyntax.self) {
                if let scope = quickScope.peek(), let scope {
                    quickScope.push((kind: scope.kind, blockId: elements.id))
                } else {
                    quickScope.push(nil)
                }
                walk(elements)
                quickScope.pop()
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
    case justBeforeEach
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

private extension Stack where Element == ScopeElement {
    func lastSuspiciousScope(_ node: any SyntaxProtocol) -> ScopeElement {
        if let scope = peek(), let scope,
           QuickCallKind.restrictiveKinds.contains(scope.kind),
           node.parent?.is(CodeBlockItemSyntax.self) == true,
           node.parent?.parent?.id == scope.blockId {
            return scope
        }
        return nil
    }
}

private extension ReasonedRuleViolation {
    static func violation(at position: AbsolutePosition, kind: QuickCallKind) -> Self {
        .init(position: position, reason: "Discouraged call inside a '\(kind)' block")
    }
}

private final class FunctionCallFinder: SyntaxVisitor {
    private(set) var found = false

    override func visit(_: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }
}
