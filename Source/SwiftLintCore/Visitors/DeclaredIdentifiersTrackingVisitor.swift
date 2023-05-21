import SwiftSyntax

/// A specialized `ViolationsSyntaxVisitor` that tracks declared identifiers per scope while traversing the AST.
open class DeclaredIdentifiersTrackingVisitor: ViolationsSyntaxVisitor {
    /// A type that remembers the declared identifers (in order) up to the current position in the code.
    public typealias Scope = Stack<Set<String>>

    /// The hierarchical stack of identifiers declared up to the current position in the code.
    public private(set) var scope: Scope

    /// Initializer.
    ///
    /// - parameter scope: A (potentially already pre-filled) scope to collect identifers into.
    public init(scope: Scope = Scope()) {
        self.scope = scope
        super.init(viewMode: .sourceAccurate)
    }

    /// Indicate whether a given identifier is in scope.
    ///
    /// - parameter identifier: An identifier.
    public func hasSeenDeclaration(for identifier: String) -> Bool {
        scope.contains { $0.contains(identifier) }
    }

    // swiftlint:disable:next cyclomatic_complexity
    override open func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        guard let parent = node.parent, !parent.is(SourceFileSyntax.self), let grandParent = parent.parent else {
            return .visitChildren
        }
        scope.openChildScope()
        if let ifStmt = grandParent.as(IfExprSyntax.self), parent.keyPathInParent != \IfExprSyntax.elseBody {
            collectIdentifiers(fromConditions: ifStmt.conditions)
        } else if let whileStmt = grandParent.as(WhileStmtSyntax.self) {
            collectIdentifiers(fromConditions: whileStmt.conditions)
        } else if let pattern = grandParent.as(ForInStmtSyntax.self)?.pattern {
            collectIdentifiers(fromPattern: pattern)
        } else if let parameters = grandParent.as(FunctionDeclSyntax.self)?.signature.input.parameterList {
            parameters.forEach { scope.addToCurrentScope(($0.secondName ?? $0.firstName).text) }
        } else if let input = parent.as(ClosureExprSyntax.self)?.signature?.input {
            switch input {
            case let .input(parameters):
                parameters.parameterList.forEach { scope.addToCurrentScope(($0.secondName ?? $0.firstName).text) }
            case let .simpleInput(parameters):
                parameters.forEach { scope.addToCurrentScope($0.name.text) }
            }
        } else if let switchCase = parent.as(SwitchCaseSyntax.self)?.label.as(SwitchCaseLabelSyntax.self) {
            switchCase.caseItems
                .compactMap { $0.pattern.as(ValueBindingPatternSyntax.self)?.valuePattern ?? $0.pattern }
                .compactMap { $0.as(ExpressionPatternSyntax.self)?.expression.asFunctionCall }
                .compactMap { $0.argumentList.as(TupleExprElementListSyntax.self) }
                .flatMap { $0 }
                .compactMap { $0.expression.as(UnresolvedPatternExprSyntax.self) }
                .compactMap { $0.pattern.as(ValueBindingPatternSyntax.self)?.valuePattern ?? $0.pattern }
                .compactMap { $0.as(IdentifierPatternSyntax.self) }
                .forEach { scope.addToCurrentScope($0.identifier.text) }
        } else if let catchClause = grandParent.as(CatchClauseSyntax.self) {
            if let items = catchClause.catchItems {
                items
                    .compactMap { $0.pattern?.as(ValueBindingPatternSyntax.self)?.valuePattern }
                    .forEach(collectIdentifiers(fromPattern:))
            } else {
                // A catch clause without explicit catch items has an implicit `error` variable in scope.
                scope.addToCurrentScope("error")
            }
        }
        return .visitChildren
    }

    override open func visitPost(_ node: CodeBlockItemListSyntax) {
        scope.pop()
    }

    override open func visitPost(_ node: VariableDeclSyntax) {
        if node.parent?.is(MemberDeclListItemSyntax.self) != true {
            for binding in node.bindings {
                collectIdentifiers(fromPattern: binding.pattern)
            }
        }
    }

    override open func visitPost(_ node: GuardStmtSyntax) {
        collectIdentifiers(fromConditions: node.conditions)
    }

    private func collectIdentifiers(fromConditions conditions: ConditionElementListSyntax) {
        conditions
            .compactMap { $0.condition.as(OptionalBindingConditionSyntax.self)?.pattern }
            .forEach { collectIdentifiers(fromPattern: $0) }
    }

    private func collectIdentifiers(fromPattern pattern: PatternSyntax) {
        if let name = pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
            scope.addToCurrentScope(name)
        }
    }
}

private extension DeclaredIdentifiersTrackingVisitor.Scope {
    mutating func addToCurrentScope(_ identifier: String) {
        modifyLast { $0.insert(identifier) }
    }

    mutating func openChildScope() {
        push([])
    }
}
