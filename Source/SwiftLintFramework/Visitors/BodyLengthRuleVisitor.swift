import SwiftSyntax

final class BodyLengthRuleVisitor: ViolationsSyntaxVisitor {
    private let kind: Kind
    private let file: SwiftLintFile
    private let configuration: SeverityLevelsConfiguration
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

    init(kind: Kind, file: SwiftLintFile, configuration: SeverityLevelsConfiguration) {
        self.kind = kind
        self.file = file
        self.configuration = configuration
        locationConverter = file.locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        if kind == .type {
            registerViolations(
                getLeftBrace: { node.members.leftBrace },
                getRightBrace: { node.members.rightBrace },
                getViolationNode: { node.enumKeyword }
            )
        }
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        if kind == .type {
            registerViolations(
                getLeftBrace: { node.members.leftBrace },
                getRightBrace: { node.members.rightBrace },
                getViolationNode: { node.classKeyword }
            )
        }
    }

    override func visitPost(_ node: StructDeclSyntax) {
        if kind == .type {
            registerViolations(
                getLeftBrace: { node.members.leftBrace },
                getRightBrace: { node.members.rightBrace },
                getViolationNode: { node.structKeyword }
            )
        }
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        if kind == .type {
            registerViolations(
                getLeftBrace: { node.members.leftBrace },
                getRightBrace: { node.members.rightBrace },
                getViolationNode: { node.actorKeyword }
            )
        }
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        if kind == .closure {
            registerViolations(
                getLeftBrace: { node.leftBrace },
                getRightBrace: { node.rightBrace },
                getViolationNode: { node.leftBrace }
            )
        }
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if kind == .function {
            registerViolations(
                getLeftBrace: { node.body?.leftBrace },
                getRightBrace: { node.body?.rightBrace },
                getViolationNode: { node.identifier }
            )
        }
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
        if kind == .function {
            registerViolations(
                getLeftBrace: { node.body?.leftBrace },
                getRightBrace: { node.body?.rightBrace },
                getViolationNode: { node.initKeyword }
            )
        }
    }

    private func registerViolations(
        getLeftBrace: () -> TokenSyntax?, getRightBrace: () -> TokenSyntax?, getViolationNode: () -> some SyntaxProtocol
    ) {
        guard
            let leftBracePosition = getLeftBrace()?.positionAfterSkippingLeadingTrivia,
            let leftBraceLine = locationConverter.location(for: leftBracePosition).line,
            let rightBracePosition = getRightBrace()?.positionAfterSkippingLeadingTrivia,
            let rightBraceLine = locationConverter.location(for: rightBracePosition).line
        else {
            return
        }

        let lineCount = file.bodyLineCountIgnoringCommentsAndWhitespace(leftBraceLine: leftBraceLine,
                                                                        rightBraceLine: rightBraceLine)
        guard lineCount > configuration.warning else {
            return
        }

        let severity: ViolationSeverity
        if let error = configuration.error, lineCount > error {
            severity = .error
        } else {
            severity = .warning
        }

        let reason = """
            \(kind.name) body should span \(configuration.warning) lines or less excluding comments and whitespace: \
            currently spans \(lineCount) lines
            """

        let violation = ReasonedRuleViolation(
            position: getViolationNode().positionAfterSkippingLeadingTrivia,
            reason: reason,
            severity: severity
        )
        violations.append(violation)
    }
}
