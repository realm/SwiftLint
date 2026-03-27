import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MissingDocsRule: Rule {
    var configuration = MissingDocsConfiguration()

    static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Declarations should be documented.",
        kind: .lint,
        nonTriggeringExamples: MissingDocsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MissingDocsRuleExamples.triggeringExamples
    )
}

private extension MissingDocsRule {
    final class Visitor: EffectiveAccessControlSyntaxVisitor<ConfigurationType> {
        init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(
                configuration: configuration,
                file: file,
                evaluateEffectiveAcl: configuration.evaluateEffectiveAccessControlLevel
            )
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inherits, configuration.excludesInheritedTypes {
                _ = super.visit(node)
                return .skipChildren
            }
            collectViolation(from: node, on: node.actorKeyword)
            return super.visit(node)
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            collectViolation(from: node, on: node.associatedtypeKeyword)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inherits, configuration.excludesInheritedTypes {
                _ = super.visit(node)
                return .skipChildren
            }
            collectViolation(from: node, on: node.classKeyword)
            return super.visit(node)
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visitPost(_ node: EnumCaseDeclSyntax) {
            guard !node.hasDocComment, let enumAccessControlLevel else {
                return
            }
            if let parameter = configuration.parameters.first(where: { $0.value == enumAccessControlLevel }) {
                violations.append(
                    .init(
                        position: node.caseKeyword.positionAfterSkippingLeadingTrivia,
                        reason: "\(enumAccessControlLevel) declarations should be documented",
                        severity: parameter.severity
                    )
                )
            }
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inherits, configuration.excludesInheritedTypes {
                _ = super.visit(node)
                return .skipChildren
            }
            collectViolation(from: node, on: node.enumKeyword)
            return super.visit(node)
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inherits, configuration.excludesInheritedTypes {
                _ = super.visit(node)
                return .skipChildren
            }
            if !configuration.excludesExtensions {
                collectViolation(from: node, on: node.extensionKeyword)
            }
            return super.visit(node)
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolation(from: node, on: node.funcKeyword)
            return .skipChildren
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.signature.parameterClause.parameters.isNotEmpty || !configuration.excludesTrivialInit {
                collectViolation(from: node, on: node.initKeyword)
            }
            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inherits, configuration.excludesInheritedTypes {
                _ = super.visit(node)
                return .skipChildren
            }
            collectViolation(from: node, on: node.protocolKeyword)
            return super.visit(node)
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inherits, configuration.excludesInheritedTypes {
                _ = super.visit(node)
                return .skipChildren
            }
            collectViolation(from: node, on: node.structKeyword)
            return super.visit(node)
        }

        override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolation(from: node, on: node.subscriptKeyword)
            return .skipChildren
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            collectViolation(from: node, on: node.typealiasKeyword)
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolation(from: node, on: node.bindingSpecifier)
            return .skipChildren
        }

        private func collectViolation(from node: some WithModifiersSyntax, on token: TokenSyntax) {
            if node.modifiers.contains(keyword: .override) || node.hasDocComment {
                return
            }
            let acl = effectiveAccessControlLevel(for: node.modifiers)
            if let parameter = configuration.parameters.first(where: { $0.value == acl }) {
                violations.append(
                    ReasonedRuleViolation(
                        position: token.positionAfterSkippingLeadingTrivia,
                        reason: "\(acl) declarations should be documented",
                        severity: parameter.severity
                    )
                )
            }
        }
    }
}

private extension DeclGroupSyntax {
    var inherits: Bool {
        if let types = inheritanceClause?.inheritedTypes, types.isNotEmpty {
            return types.contains { !$0.type.is(SuppressedTypeSyntax.self) }
        }
        return false
    }
}

private extension SyntaxProtocol {
    var hasDocComment: Bool {
        switch leadingTrivia.pieces.last(where: { !$0.isWhitespace }) {
        case .docBlockComment, .docLineComment:
            return true
        default:
            guard let item = parent?.as(CodeBlockItemSyntax.self),
                  let itemList = item.parent?.as(CodeBlockItemListSyntax.self),
                  itemList.first == item else {
                return false
            }
            let ifConfigDecl = itemList
                .parent?.as(IfConfigClauseSyntax.self)?
                .parent?.as(IfConfigClauseListSyntax.self)?
                .parent?.as(IfConfigDeclSyntax.self)
            if let ifConfigDecl {
                return ifConfigDecl.hasDocComment
            }
            return false
        }
    }
}
