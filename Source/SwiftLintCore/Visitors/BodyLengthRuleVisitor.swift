import SwiftSyntax

/// Visitor that collection violations of code block lengths.
public final class BodyLengthRuleVisitor<Parent: Rule>: ViolationsSyntaxVisitor<SeverityLevelsConfiguration<Parent>> {
    @usableFromInline let kind: Kind

    /// The code block types to check.
    public enum Kind {
        /// Closure code blocks.
        case closure
        /// Function body blocks.
        case function
        /// Type (class, enum, ...) member blocks.
        case type

        fileprivate var name: String {
            switch self {
            case .closure:
                return "Closure"
            case .function:
                return "Function"
            case .type:
                return "Type"
            }
        }
    }

    /// Initializer.
    ///
    /// - Parameters:
    ///   - kind: The code block type to check. See ``Kind``.
    ///   - file: The file to collect violation for.
    ///   - configuration: The configuration that defines the acceptable limits.
    @inlinable
    public init(kind: Kind, file: SwiftLintFile, configuration: SeverityLevelsConfiguration<Parent>) {
        self.kind = kind
        super.init(configuration: configuration, file: file)
    }

    override public func visitPost(_ node: EnumDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.enumKeyword
            )
        }
    }

    override public func visitPost(_ node: ClassDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.classKeyword
            )
        }
    }

    override public func visitPost(_ node: StructDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.structKeyword
            )
        }
    }

    override public func visitPost(_ node: ActorDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.actorKeyword
            )
        }
    }

    override public func visitPost(_ node: ClosureExprSyntax) {
        if kind == .closure {
            registerViolations(
                leftBrace: node.leftBrace,
                rightBrace: node.rightBrace,
                violationNode: node.leftBrace
            )
        }
    }

    override public func visitPost(_ node: FunctionDeclSyntax) {
        if kind == .function, let body = node.body {
            registerViolations(
                leftBrace: body.leftBrace,
                rightBrace: body.rightBrace,
                violationNode: node.name
            )
        }
    }

    override public func visitPost(_ node: InitializerDeclSyntax) {
        if kind == .function, let body = node.body {
            registerViolations(
                leftBrace: body.leftBrace,
                rightBrace: body.rightBrace,
                violationNode: node.initKeyword
            )
        }
    }

    private func registerViolations(
        leftBrace: TokenSyntax, rightBrace: TokenSyntax, violationNode: some SyntaxProtocol
    ) {
        let leftBracePosition = leftBrace.positionAfterSkippingLeadingTrivia
        let leftBraceLine = locationConverter.location(for: leftBracePosition).line
        let rightBracePosition = rightBrace.positionAfterSkippingLeadingTrivia
        let rightBraceLine = locationConverter.location(for: rightBracePosition).line
        let lineCount = file.bodyLineCountIgnoringCommentsAndWhitespace(leftBraceLine: leftBraceLine,
                                                                        rightBraceLine: rightBraceLine)
        let severity: ViolationSeverity, upperBound: Int
        if let error = configuration.error, lineCount > error {
            severity = .error
            upperBound = error
        } else if lineCount > configuration.warning {
            severity = .warning
            upperBound = configuration.warning
        } else {
            return
        }

        let reason = """
            \(kind.name) body should span \(upperBound) lines or less excluding comments and whitespace: \
            currently spans \(lineCount) lines
            """

        let violation = ReasonedRuleViolation(
            position: violationNode.positionAfterSkippingLeadingTrivia,
            reason: reason,
            severity: severity
        )
        violations.append(violation)
    }
}
