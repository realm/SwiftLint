import SwiftSyntax

/// A specialized `ViolationsSyntaxVisitor` that tracks declared identifiers per scope while traversing the AST.
open class DeclaredIdentifiersTrackingVisitor<Configuration: RuleConfiguration>:
        ViolationsSyntaxVisitor<Configuration> {
    /// A type that remembers the declared identifiers (in order) up to the current position in the code.
    public typealias Scope = Stack<Set<String>>

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
        scope.contains { $0.contains(identifier) }
    }

    override open func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        guard let parent = node.parent, !parent.is(SourceFileSyntax.self), let grandParent = parent.parent else {
            return .visitChildren
        }
        scope.openChildScope()
        if let ifStmt = grandParent.as(IfExprSyntax.self), parent.keyPathInParent != \IfExprSyntax.elseBody {
            collectIdentifiers(from: ifStmt.conditions)
        } else if let whileStmt = grandParent.as(WhileStmtSyntax.self) {
            collectIdentifiers(from: whileStmt.conditions)
        } else if let pattern = grandParent.as(ForStmtSyntax.self)?.pattern {
            collectIdentifiers(from: pattern)
        } else if let parameters = grandParent.as(FunctionDeclSyntax.self)?.signature.parameterClause.parameters {
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

    private func collectIdentifiers(from parameters: FunctionParameterListSyntax) {
        parameters.forEach { scope.addToCurrentScope(($0.secondName ?? $0.firstName).text) }
    }

    private func collectIdentifiers(from closureParameters: ClosureSignatureSyntax.ParameterClause) {
        switch closureParameters {
        case let .parameterClause(parameters):
            parameters.parameters.forEach { scope.addToCurrentScope(($0.secondName ?? $0.firstName).text) }
        case let .simpleInput(parameters):
            parameters.forEach { scope.addToCurrentScope($0.name.text) }
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
            .forEach { scope.addToCurrentScope($0.identifier.text) }
    }

    private func collectIdentifiers(from catchClause: CatchClauseSyntax) {
        let items = catchClause.catchItems
        if items.isNotEmpty {
            items
                .compactMap { $0.pattern?.as(ValueBindingPatternSyntax.self)?.pattern }
                .forEach(collectIdentifiers(from:))
        } else {
            // A catch clause without explicit catch items has an implicit `error` variable in scope.
            scope.addToCurrentScope("error")
        }
    }

    private func collectIdentifiers(from conditions: ConditionElementListSyntax) {
        conditions
            .compactMap { $0.condition.as(OptionalBindingConditionSyntax.self)?.pattern }
            .forEach { collectIdentifiers(from: $0) }
    }

    private func collectIdentifiers(from pattern: PatternSyntax) {
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
