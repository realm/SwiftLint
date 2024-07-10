import SwiftSyntax

public enum Declaration: Hashable {
    case parameter(position: AbsolutePosition, name: String)
    case localVariable(position: AbsolutePosition, name: String)
    case implicitVariable(name: String)
    case stopMarker

    public var name: String {
        switch self {
        case let .parameter(_, name): name
        case let .localVariable(_, name): name
        case let .implicitVariable(name): name
        case .stopMarker: ""
        }
    }
}

/// A specialized `ViolationsSyntaxVisitor` that tracks declared identifiers per scope while traversing the AST.
open class DeclaredIdentifiersTrackingVisitor<Configuration: RuleConfiguration>:
        ViolationsSyntaxVisitor<Configuration> {
    /// A type that remembers the declared identifiers (in order) up to the current position in the code.
    public typealias Scope = Stack<Set<Declaration>>

    /// The hierarchical stack of identifiers declared up to the current position in the code.
    public var scope: Scope

    /// Initializer.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of a rule.
    ///   - file: File from which the syntax tree stems from.
    ///   - scope: A (potentially already pre-filled) scope to collect identifiers into.
    @inlinable
    public init(configuration: Configuration, file: SwiftLintFile, scope: Scope = Scope()) {
        self.scope = scope
        super.init(configuration: configuration, file: file)
    }

    /// Indicate whether a given identifier is in scope.
    ///
    /// - parameter identifier: An identifier.
    public func hasSeenDeclaration(for identifier: String) -> Bool {
        scope.contains { $0.contains { $0.name == identifier } }
    }

    override open func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        scope.openChildScope()
        guard let parent = node.parent, !parent.is(SourceFileSyntax.self), let grandParent = parent.parent else {
            return .visitChildren
        }
        if let ifStmt = grandParent.as(IfExprSyntax.self), parent.keyPathInParent != \IfExprSyntax.elseBody {
            collectIdentifiers(from: ifStmt.conditions)
        } else if let whileStmt = grandParent.as(WhileStmtSyntax.self) {
            collectIdentifiers(from: whileStmt.conditions)
        } else if let pattern = grandParent.as(ForStmtSyntax.self)?.pattern {
            collectIdentifiers(from: pattern)
        } else if let parameters = grandParent.as(FunctionDeclSyntax.self)?.signature.parameterClause.parameters {
            collectIdentifiers(from: parameters)
        } else if let parameters = grandParent.as(InitializerDeclSyntax.self)?.signature.parameterClause.parameters {
            collectIdentifiers(from: parameters)
        } else if let parameters = grandParent.as(SubscriptDeclSyntax.self)?.parameterClause.parameters {
            collectIdentifiers(from: parameters)
        } else if let closureParameters = parent.as(ClosureExprSyntax.self)?.signature?.parameterClause {
            collectIdentifiers(from: closureParameters)
        } else if let switchCase = parent.as(SwitchCaseSyntax.self)?.label.as(SwitchCaseLabelSyntax.self) {
            collectIdentifiers(from: switchCase)
        } else if let catchClause = grandParent.as(CatchClauseSyntax.self) {
            collectIdentifiers(from: catchClause)
        }
        return .visitChildren
    }

    override open func visitPost(_ node: CodeBlockItemListSyntax) {
        scope.pop()
    }

    override open func visitPost(_ node: VariableDeclSyntax) {
        if node.parent?.is(MemberBlockItemSyntax.self) != true {
            for binding in node.bindings {
                collectIdentifiers(from: binding.pattern)
            }
        }
    }

    override open func visitPost(_ node: GuardStmtSyntax) {
        collectIdentifiers(from: node.conditions)
    }

    // MARK: Type declaration boundaries

    override open func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
        if node.belongsToTypeDefinableInFunction {
            scope.push([.stopMarker])
        }
        return .visitChildren
    }

    override open func visitPost(_ node: MemberBlockSyntax) {
        if node.belongsToTypeDefinableInFunction {
            scope.pop()
        }
    }

    // MARK: Private methods

    private func collectIdentifiers(from parameters: FunctionParameterListSyntax) {
        for param in parameters {
            let name = param.secondName ?? param.firstName
            if name.tokenKind != .wildcard {
                scope.addToCurrentScope(.parameter(position: name.positionAfterSkippingLeadingTrivia, name: name.text))
            }
        }
    }

    private func collectIdentifiers(from closureParameters: ClosureSignatureSyntax.ParameterClause) {
        switch closureParameters {
        case let .parameterClause(parameters):
            for param in parameters.parameters {
                let name = param.secondName ?? param.firstName
                scope.addToCurrentScope(.parameter(position: name.positionAfterSkippingLeadingTrivia, name: name.text))
            }
        case let .simpleInput(parameters):
            for param in parameters {
                let name = param.name
                scope.addToCurrentScope(.parameter(position: name.positionAfterSkippingLeadingTrivia, name: name.text))
            }
        }
    }

    private func collectIdentifiers(from switchCase: SwitchCaseLabelSyntax) {
        switchCase.caseItems
            .map { item -> PatternSyntax in
                item.pattern.as(ValueBindingPatternSyntax.self)?.pattern ?? item.pattern
            }
            .compactMap { pattern -> FunctionCallExprSyntax? in
                pattern.as(ExpressionPatternSyntax.self)?.expression.asFunctionCall
            }
            .map { call -> LabeledExprListSyntax in
                call.arguments
            }
            .flatMap { $0 }
            .compactMap { labeledExpr -> PatternExprSyntax? in
                labeledExpr.expression.as(PatternExprSyntax.self)
            }
            .map { patternExpr -> any PatternSyntaxProtocol in
                patternExpr.pattern.as(ValueBindingPatternSyntax.self)?.pattern ?? patternExpr.pattern
            }
            .compactMap { pattern -> IdentifierPatternSyntax? in
                pattern.as(IdentifierPatternSyntax.self)
            }
            .forEach {
                let id = $0.identifier
                scope.addToCurrentScope(.localVariable(position: id.positionAfterSkippingLeadingTrivia, name: id.text))
            }
    }

    private func collectIdentifiers(from catchClause: CatchClauseSyntax) {
        let items = catchClause.catchItems
        if items.isEmpty {
            // A catch clause without explicit catch items has an implicit `error` variable in scope.
            scope.addToCurrentScope(.implicitVariable(name: "error"))
        } else {
            items
                .compactMap { $0.pattern?.as(ValueBindingPatternSyntax.self)?.pattern }
                .forEach(collectIdentifiers(from:))
        }
    }

    private func collectIdentifiers(from conditions: ConditionElementListSyntax) {
        conditions
            .compactMap { $0.condition.as(OptionalBindingConditionSyntax.self)?.pattern }
            .forEach { collectIdentifiers(from: $0) }
    }

    private func collectIdentifiers(from pattern: PatternSyntax) {
        if let id = pattern.as(IdentifierPatternSyntax.self)?.identifier {
            scope.addToCurrentScope(.localVariable(position: id.positionAfterSkippingLeadingTrivia, name: id.text))
        }
    }
}

private extension DeclaredIdentifiersTrackingVisitor.Scope {
    mutating func addToCurrentScope(_ decl: Declaration) {
        modifyLast { $0.insert(decl) }
    }

    mutating func openChildScope() {
        push([])
    }
}

private extension MemberBlockSyntax {
    var belongsToTypeDefinableInFunction: Bool {
        if let parent {
            return [.actorDecl, .classDecl, .enumDecl, .structDecl].contains(parent.kind)
        }
        return false
    }
}
