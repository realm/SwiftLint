import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct MissingDocsRule: OptInRule {
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
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var aclScope = Stack<AccessControlBehavior>()

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            defer {
                aclScope.push(
                    behavior: .actor(node.modifiers.accessibility),
                    evalEffectiveAcl: configuration.evaluateEffectiveAccessControlLevel
                )
            }
            if node.inherits, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.actorKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            aclScope.pop()
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            collectViolation(from: node, on: node.associatedtypeKeyword)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            defer {
                aclScope.push(
                    behavior: .class(node.modifiers.accessibility),
                    evalEffectiveAcl: configuration.evaluateEffectiveAccessControlLevel
                )
            }
            if node.inherits, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.classKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visitPost(_ node: EnumCaseDeclSyntax) {
            guard !node.hasDocComment, case let .enum(enumAcl) = aclScope.peek() else {
                return
            }
            let acl = enumAcl ?? .internal
            if let parameter = configuration.parameters.first(where: { $0.value == acl }) {
                node.elements.forEach {
                    violations.append(
                        ReasonedRuleViolation(
                            position: $0.name.positionAfterSkippingLeadingTrivia,
                            reason: "\(acl) declarations should be documented",
                            severity: parameter.severity
                        )
                    )
                }
            }
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            defer {
                aclScope.push(
                    behavior: .enum(node.modifiers.accessibility),
                    evalEffectiveAcl: configuration.evaluateEffectiveAccessControlLevel
                )
            }
            if node.inherits, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.enumKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            defer { aclScope.push(.extension(node.modifiers.accessibility)) }
            if node.inherits, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            if !configuration.excludesExtensions {
                collectViolation(from: node, on: node.extensionKeyword)
            }
            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            aclScope.pop()
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
            defer {
                aclScope.push(
                    behavior: .protocol(node.modifiers.accessibility),
                    evalEffectiveAcl: configuration.evaluateEffectiveAccessControlLevel
                )
            }
            if node.inherits, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.protocolKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            defer {
                aclScope.push(
                    behavior: .struct(node.modifiers.accessibility),
                    evalEffectiveAcl: configuration.evaluateEffectiveAccessControlLevel
                )
            }
            if node.inherits, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.structKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            aclScope.pop()
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
            let acl = aclScope.computeAcl(
                givenExplicitAcl: node.modifiers.accessibility,
                evalEffectiveAcl: configuration.evaluateEffectiveAccessControlLevel
            )
            if let parameter = configuration.parameters.first(where: { $0.value == acl }) {
                violations.append(
                    ReasonedRuleViolation(
                        position: (node.modifiers.staticOrClass ?? token).positionAfterSkippingLeadingTrivia,
                        reason: "\(acl) declarations should be documented",
                        severity: parameter.severity
                    )
                )
            }
        }
    }
}

private extension WithModifiersSyntax {
    var hasDocComment: Bool {
        switch leadingTrivia.pieces.last(where: { !$0.isWhitespace }) {
        case .docBlockComment, .docLineComment: true
        default: false
        }
    }
}

private extension DeclGroupSyntax {
    var inherits: Bool {
        if let types = inheritanceClause?.inheritedTypes, types.isNotEmpty {
            return types.contains { !$0.isUncopyable }
        }
        return false
    }
}

private extension InheritedTypeSyntax {
    var isUncopyable: Bool {
        if let suppressedType = type.as(SuppressedTypeSyntax.self) {
            return suppressedType.type.as(IdentifierTypeSyntax.self)?.name.text == "Copyable"
        }
        return false
    }
}

private extension SyntaxProtocol {
    var parentDeclGroup: (any DeclGroupSyntax)? {
        guard let parent else {
            return nil
        }
        if let declGroup = parent.asProtocol((any DeclGroupSyntax).self) {
            return declGroup
        }
        return parent.parentDeclGroup
    }

    var defaultAccessibility: AccessControlLevel {
        if let declGroup = parentDeclGroup,
           declGroup.is(ExtensionDeclSyntax.self) || declGroup.is(ProtocolDeclSyntax.self),
           let accessibility = declGroup.modifiers.accessibility {
            return accessibility
        }
        return .internal
    }
}

private extension DeclModifierListSyntax {
    var accessibility: AccessControlLevel? {
        filter { $0.detail == nil }.compactMap { AccessControlLevel(description: $0.name.text) }.first
    }

    var staticOrClass: TokenSyntax? {
        first { $0.name.text == "static" || $0.name.text == "class" }?.name
    }
}

private enum AccessControlBehavior {
    case `actor`(AccessControlLevel?)
    case local
    case `class`(AccessControlLevel?)
    case `enum`(AccessControlLevel?)
    case `extension`(AccessControlLevel?)
    case `protocol`(AccessControlLevel?)
    case `struct`(AccessControlLevel?)

    var effectiveAcl: AccessControlLevel {
        explicitAcl ?? .internal
    }

    var explicitAcl: AccessControlLevel? {
        switch self {
        case let .actor(acl): acl
        case .local: nil
        case let .class(acl): acl
        case let .enum(acl): acl
        case let .extension(acl): acl
        case let .protocol(acl): acl
        case let .struct(acl): acl
        }
    }

    func sameWith(acl: AccessControlLevel) -> Self {
        switch self {
        case .actor: .actor(acl)
        case .local: .local
        case .class: .class(acl)
        case .enum: .enum(acl)
        case .extension: .extension(acl)
        case .protocol: .protocol(acl)
        case .struct: .struct(acl)
        }
    }
}

/// Implementation of Swift's effective ACL logic. Should be moved to a specialized syntax visitor for reuse some time.
private extension Stack<AccessControlBehavior> {
    mutating func push(behavior: AccessControlBehavior, evalEffectiveAcl: Bool) {
        if let parentBehavior = peek() {
            switch parentBehavior {
            case .local:
                push(.local)
            case .actor, .class, .struct, .enum:
                if behavior.effectiveAcl <= parentBehavior.effectiveAcl || !evalEffectiveAcl {
                    push(behavior)
                } else {
                    push(behavior.sameWith(acl: parentBehavior.effectiveAcl))
                }
            case .extension, .protocol:
                if behavior.explicitAcl != nil {
                    push(behavior)
                } else {
                    push(behavior.sameWith(acl: parentBehavior.effectiveAcl))
                }
            }
        } else {
            push(behavior)
        }
    }

    func computeAcl(givenExplicitAcl acl: AccessControlLevel?, evalEffectiveAcl: Bool) -> AccessControlLevel {
        if let parentBehavior = peek() {
            switch parentBehavior {
               case .local:
                   .private
               case .actor, .class, .struct, .enum:
                   if let acl {
                       acl < parentBehavior.effectiveAcl || !evalEffectiveAcl ? acl : parentBehavior.effectiveAcl
                   } else {
                       parentBehavior.effectiveAcl >= .internal ? .internal : parentBehavior.effectiveAcl
                   }
               case .protocol:
                   parentBehavior.effectiveAcl
               case .extension:
                   acl ?? parentBehavior.effectiveAcl
               }
        } else {
            acl ?? .internal
        }
    }
}
