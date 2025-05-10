import Foundation
import SwiftSyntax

/// An identifier declaration.
public enum IdentifierDeclaration: Hashable {
    /// Parameter declaration with a name token.
    case parameter(name: TokenSyntax)
    /// Local variable declaration with a name token.
    case localVariable(name: TokenSyntax)
    /// A variable that is implicitly added by the compiler (e.g. `error` in `catch` clauses).
    case implicitVariable(name: String)
    /// A variable hidden from scope because its name is a wildcard `_`.
    case wildcard
    /// Special case that marks a type boundary at which name lookup stops.
    case lookupBoundary

    /// The name of the declared identifier (e.g. in `let a = 1` this is `a`).
    fileprivate var name: String {
        switch self {
        case let .parameter(name): name.text
        case let .localVariable(name): name.text
        case let .implicitVariable(name): name
        case .wildcard: "_"
        case .lookupBoundary: ""
        }
    }

    /// Check whether self declares a variable given by name.
    ///
    /// - Parameters:
    ///   - id: Name of the variable.
    ///   - disregardBackticks: If `true`, normalize all names before comparison by removing all backticks. This is the
    ///                         default since backticks only disambiguate, but don't contribute to name resolution.
    public func declares(id: String, disregardBackticks: Bool = true) -> Bool {
        if self == .wildcard || id == "_" {
            // Insignificant names cannot refer to each other.
            return false
        }
        if disregardBackticks {
            let backticks = CharacterSet(charactersIn: "`")
            return id.trimmingCharacters(in: backticks) == name.trimmingCharacters(in: backticks)
        }
        return id == name
    }
}

/// A specialized `ViolationsSyntaxVisitor` that tracks declared identifiers per scope while traversing the AST.
open class DeclaredIdentifiersTrackingVisitor<Configuration: RuleConfiguration>:
        ViolationsSyntaxVisitor<Configuration> {
    /// A type that remembers the declared identifiers (in order) up to the current position in the code.
    public typealias Scope = Stack<[IdentifierDeclaration]>

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
    /// - Parameters:
    ///   - identifier: An identifier.
    /// - Returns: `true` if the identifier was declared previously.
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

    override open func visitPost(_: CodeBlockItemListSyntax) {
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
            scope.push([.lookupBoundary])
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
            scope.addToCurrentScope(.parameter(name: name))
        }
    }

    private func collectIdentifiers(from closureParameters: ClosureSignatureSyntax.ParameterClause) {
        switch closureParameters {
        case let .parameterClause(parameters):
            for param in parameters.parameters {
                let name = param.secondName ?? param.firstName
                scope.addToCurrentScope(.parameter(name: name))
            }
        case let .simpleInput(parameters):
            for param in parameters {
                let name = param.name
                scope.addToCurrentScope(.parameter(name: name))
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
            .map(\.arguments)
            .flatMap { $0 }
            .compactMap { labeledExpr -> PatternExprSyntax? in
                labeledExpr.expression.as(PatternExprSyntax.self)
            }
            .map { patternExpr -> any PatternSyntaxProtocol in
                patternExpr.pattern.as(ValueBindingPatternSyntax.self)?.pattern ?? patternExpr.pattern
            }
            .forEach {
                collectIdentifiers(from: PatternSyntax(fromProtocol: $0))
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
            scope.addToCurrentScope(.localVariable(name: id))
        }
    }
}

private extension DeclaredIdentifiersTrackingVisitor.Scope {
    mutating func addToCurrentScope(_ decl: IdentifierDeclaration) {
        modifyLast { $0.append(decl.name == "_" ? .wildcard : decl) }
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
