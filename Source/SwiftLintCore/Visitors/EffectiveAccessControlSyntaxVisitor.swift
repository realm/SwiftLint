import SwiftSyntax

/// A `ViolationsSyntaxVisitor` with helpers to compute effective access control levels for declarations.
open class EffectiveAccessControlSyntaxVisitor<Configuration: RuleConfiguration>:
        ViolationsSyntaxVisitor<Configuration> {
    /// Whether to apply the effective access control level computation or to use the explicitly
    /// declared access control level.
    public let evaluateEffectiveAcl: Bool

    private var aclScope = Stack<AccessControlBehavior>()

    /// Creates a new `EffectiveAccessControlSyntaxVisitor`.
    ///
    /// - Parameters:
    ///   - configuration: The rule configuration to use for this visitor.
    ///   - file: The file to analyze.
    ///   - evaluateEffectiveAcl: Whether to apply the effective access control level computation or to use the
    ///                           explicitly declared access control level.
    @inlinable
    public init(configuration: Configuration, file: SwiftLintFile, evaluateEffectiveAcl: Bool = true) {
        self.evaluateEffectiveAcl = evaluateEffectiveAcl
        super.init(configuration: configuration, file: file)
    }

    private enum AccessControlScope {
        case `actor`
        case local
        case `class`
        case `enum`
        case `extension`
        case `protocol`
        case `struct`
    }

    /// Computes the effective access control level for a declaration.
    ///
    /// - Parameters:
    ///   - modifiers: Declaration modifiers that may contain an explicit access control level.
    /// - Returns: Effective access control level of this declaration.
    public func effectiveAccessControlLevel(for modifiers: DeclModifierListSyntax) -> AccessControlLevel {
        if let parentBehavior = aclScope.peek() {
            let acl = modifiers.accessibility
            switch parentBehavior {
            case .local:
                return .private
            case .actor, .class, .struct, .enum:
                if let acl {
                    let isEffectiveAclApplied = acl < parentBehavior.effectiveAcl || !evaluateEffectiveAcl
                    return isEffectiveAclApplied ? acl : parentBehavior.effectiveAcl
                }
                return parentBehavior.effectiveAcl >= .internal ? .internal : parentBehavior.effectiveAcl
            case .protocol:
                return parentBehavior.effectiveAcl
            case .extension:
                return acl ?? parentBehavior.effectiveAcl
            }
        }
        return modifiers.accessibility ?? .internal
    }

    /// Access control level of the current enum scope.
    ///
    /// - Returns: Access control level if currently in an enum scope.
    public var enumAccessControlLevel: AccessControlLevel? {
        guard case let .enum(acl) = aclScope.peek() else {
            return nil
        }
        return acl ?? .internal
    }

    /// Whether the current declaration context is local.
    public var isInLocalAccessControlScope: Bool {
        guard case .local = aclScope.peek() else {
            return false
        }
        return true
    }

    // MARK: - Automatic Scope Management

    override open func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        pushAccessControlScope(.actor, modifiers: node.modifiers)
        return .visitChildren
    }

    override open func visitPost(_: ActorDeclSyntax) {
        aclScope.pop()
    }

    override open func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        pushAccessControlScope(.class, modifiers: node.modifiers)
        return .visitChildren
    }

    override open func visitPost(_: ClassDeclSyntax) {
        aclScope.pop()
    }

    override open func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        pushAccessControlScope(.enum, modifiers: node.modifiers)
        return .visitChildren
    }

    override open func visitPost(_: EnumDeclSyntax) {
        aclScope.pop()
    }

    override open func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        pushAccessControlScope(.extension, modifiers: node.modifiers)
        return .visitChildren
    }

    override open func visitPost(_: ExtensionDeclSyntax) {
        aclScope.pop()
    }

    override open func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        pushAccessControlScope(.protocol, modifiers: node.modifiers)
        return .visitChildren
    }

    override open func visitPost(_: ProtocolDeclSyntax) {
        aclScope.pop()
    }

    override open func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        pushAccessControlScope(.struct, modifiers: node.modifiers)
        return .visitChildren
    }

    override open func visitPost(_: StructDeclSyntax) {
        aclScope.pop()
    }

    private func pushAccessControlScope(_ scope: AccessControlScope, modifiers: DeclModifierListSyntax) {
        let behavior = accessControlBehavior(scope, modifiers: modifiers)
        if let parentBehavior = aclScope.peek() {
            switch parentBehavior {
            case .local:
                aclScope.push(.local)
            case .actor, .class, .struct, .enum:
                if behavior.effectiveAcl <= parentBehavior.effectiveAcl || !evaluateEffectiveAcl {
                    aclScope.push(behavior)
                } else {
                    aclScope.push(behavior.sameWith(acl: parentBehavior.effectiveAcl))
                }
            case .extension, .protocol:
                if behavior.explicitAcl != nil {
                    aclScope.push(behavior)
                } else {
                    aclScope.push(behavior.sameWith(acl: parentBehavior.effectiveAcl))
                }
            }
        } else {
            aclScope.push(behavior)
        }
    }

    private func pushLocalAccessControlScope() {
        if let parentBehavior = aclScope.peek() {
            switch parentBehavior {
            case .local:
                aclScope.push(.local)
            case .actor, .class, .struct, .enum:
                // Local scope should always be considered private.
                aclScope.push(.local)
            case .extension, .protocol:
                aclScope.push(.local)
            }
        } else {
            aclScope.push(.local)
        }
    }

    private func accessControlBehavior(_ scope: AccessControlScope,
                                       modifiers: DeclModifierListSyntax) -> AccessControlBehavior {
        let accessibility = modifiers.accessibility
        switch scope {
        case .actor:
            return .actor(accessibility)
        case .local:
            return .local
        case .class:
            return .class(accessibility)
        case .enum:
            return .enum(accessibility)
        case .extension:
            return .extension(accessibility)
        case .protocol:
            return .protocol(accessibility)
        case .struct:
            return .struct(accessibility)
        }
    }
}

private extension DeclModifierListSyntax {
    var accessibility: AccessControlLevel? {
        filter { $0.detail == nil }.compactMap { AccessControlLevel(description: $0.name.text) }.first
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
