import SwiftSyntax

final class BodyLengthRuleVisitor<Parent: Rule>: ViolationsSyntaxVisitor {
    private let kind: Kind
    private let file: SwiftLintFile
    private let configuration: SeverityLevelsConfiguration<Parent>
    private let locationConverter: SourceLocationConverter

    enum Kind {
        case closure
        case function
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

    init(kind: Kind, file: SwiftLintFile, configuration: SeverityLevelsConfiguration<Parent>) {
        self.kind = kind
        self.file = file
        self.configuration = configuration
        locationConverter = file.locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.enumKeyword
            )
        }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.classKeyword
            )
        }
    }

    override func visitPost(_ node: StructDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.structKeyword
            )
        }
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        if kind == .type {
            registerViolations(
                leftBrace: node.memberBlock.leftBrace,
                rightBrace: node.memberBlock.rightBrace,
                violationNode: node.actorKeyword
            )
        }
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        if kind == .closure {
            registerViolations(
                leftBrace: node.leftBrace,
                rightBrace: node.rightBrace,
                violationNode: node.leftBrace
            )
        }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if kind == .function, let body = node.body {
            registerViolations(
                leftBrace: body.leftBrace,
                rightBrace: body.rightBrace,
                violationNode: node.identifier
            )
        }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
        if kind == .function, let body = node.body {
            registerViolations(
                leftBrace: body.leftBrace,
                rightBrace: body.rightBrace,
                violationNode: node.initKeyword
            )
        }
    }

    private func registerViolations(
        leftBrace: TokenSyntax, rightBrace: TokenSyntax, violationNode: SyntaxProtocol
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
