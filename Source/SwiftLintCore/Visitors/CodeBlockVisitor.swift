import SwiftSyntax

/// A visitor that collects style violations for all available code blocks.
open class CodeBlockVisitor<Configuration: RuleConfiguration>: ViolationsSyntaxVisitor<Configuration> {
    @inlinable
    override public init(configuration: Configuration, file: SwiftLintFile) {
        super.init(configuration: configuration, file: file)
    }

    override open func visitPost(_ node: AccessorDeclSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: ActorDeclSyntax) {
        collectViolations(for: node.memberBlock)
    }

    override open func visitPost(_ node: CatchClauseSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: ClassDeclSyntax) {
        collectViolations(for: node.memberBlock)
    }

    override open func visitPost(_ node: ClosureExprSyntax) {
        guard let parent = node.parent else {
            return
        }
        if parent.is(LabeledExprSyntax.self) {
            // Function parameter
            return
        }
        if parent.is(FunctionCallExprSyntax.self) || parent.is(MultipleTrailingClosureElementSyntax.self),
            node.keyPathInParent != \FunctionCallExprSyntax.calledExpression {
            // Trailing closure
            collectViolations(for: node)
        }
    }

    override open func visitPost(_ node: DeferStmtSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: DoStmtSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: EnumDeclSyntax) {
        collectViolations(for: node.memberBlock)
    }

    override open func visitPost(_ node: ExtensionDeclSyntax) {
        collectViolations(for: node.memberBlock)
    }

    override open func visitPost(_ node: FunctionDeclSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: ForStmtSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: GuardStmtSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: IfExprSyntax) {
        collectViolations(for: node.body)
        if case let .codeBlock(body) = node.elseBody {
            collectViolations(for: body)
        }
    }
    override open func visitPost(_ node: InitializerDeclSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: PatternBindingSyntax) {
        collectViolations(for: node.accessorBlock)
    }

    override open func visitPost(_ node: PrecedenceGroupDeclSyntax) {
        collectViolations(for: node)
    }

    override open func visitPost(_ node: ProtocolDeclSyntax) {
        collectViolations(for: node.memberBlock)
    }

    override open func visitPost(_ node: RepeatStmtSyntax) {
        collectViolations(for: node.body)
    }

    override open func visitPost(_ node: StructDeclSyntax) {
        collectViolations(for: node.memberBlock)
    }

    override open func visitPost(_ node: SwitchExprSyntax) {
        collectViolations(for: node)
    }

    override open func visitPost(_ node: WhileStmtSyntax) {
        collectViolations(for: node.body)
    }

    /// Collects violations for the given braced item. Intended to be specialized by subclasses.
    ///
    /// - Parameter bracedItem: The braced item to collect violations for.
    open func collectViolations(for _: (some BracedSyntax)?) {
        // Intended to be overridden.
    }
}
