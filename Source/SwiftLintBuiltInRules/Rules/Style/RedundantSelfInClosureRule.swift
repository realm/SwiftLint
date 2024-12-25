import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct RedundantSelfInClosureRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_self_in_closure",
        name: "Redundant Self in Closure",
        description: "Explicit use of 'self' is not required",
        kind: .style,
        nonTriggeringExamples: RedundantSelfInClosureRuleExamples.nonTriggeringExamples,
        triggeringExamples: RedundantSelfInClosureRuleExamples.triggeringExamples,
        corrections: RedundantSelfInClosureRuleExamples.corrections
    )
}

private enum TypeDeclarationKind {
    case likeStruct
    case likeClass
}

private enum FunctionCallType {
    case anonymousClosure
    case function
}

private enum SelfCaptureKind {
    case strong
    case weak
    case uncaptured
}

private extension RedundantSelfInClosureRule {
    final class Visitor: DeclaredIdentifiersTrackingVisitor<ConfigurationType> {
        private var typeDeclarations = Stack<TypeDeclarationKind>()
        private var functionCalls = Stack<FunctionCallType>()
        private var selfCaptures = Stack<SelfCaptureKind>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visit(_: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeClass)
            return .visitChildren
        }

        override func visitPost(_: ActorDeclSyntax) {
            typeDeclarations.pop()
        }

        override func visit(_: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeClass)
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            typeDeclarations.pop()
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            if let selfItem = node.signature?.capture?.items.first(where: \.capturesSelf) {
                selfCaptures.push(selfItem.capturesWeakly ? .weak : .strong)
            } else {
                selfCaptures.push(.uncaptured)
            }
            return .visitChildren
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            guard let activeTypeDeclarationKind = typeDeclarations.peek(),
                  let activeFunctionCallType = functionCalls.peek(),
                  let activeSelfCaptureKind = selfCaptures.peek() else {
                return
            }
            let localViolationCorrections = ExplicitSelfVisitor(
                configuration: configuration,
                file: file,
                typeDeclarationKind: activeTypeDeclarationKind,
                functionCallType: activeFunctionCallType,
                selfCaptureKind: activeSelfCaptureKind,
                scope: scope
            ).walk(tree: node.statements, handler: \.violations)
            violations.append(contentsOf: localViolationCorrections)
            selfCaptures.pop()
        }

        override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeStruct)
            return .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            typeDeclarations.pop()
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if node.calledExpression.is(ClosureExprSyntax.self) {
                functionCalls.push(.anonymousClosure)
            } else {
                functionCalls.push(.function)
            }
            return .visitChildren
        }

        override func visitPost(_: FunctionCallExprSyntax) {
            functionCalls.pop()
        }

        override func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeStruct)
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            typeDeclarations.pop()
        }
    }
}

private class ExplicitSelfVisitor<Configuration: RuleConfiguration>: DeclaredIdentifiersTrackingVisitor<Configuration> {
    private let typeDeclKind: TypeDeclarationKind
    private let functionCallType: FunctionCallType
    private let selfCaptureKind: SelfCaptureKind

    init(configuration: Configuration,
         file: SwiftLintFile,
         typeDeclarationKind: TypeDeclarationKind,
         functionCallType: FunctionCallType,
         selfCaptureKind: SelfCaptureKind,
         scope: Scope) {
        self.typeDeclKind = typeDeclarationKind
        self.functionCallType = functionCallType
        self.selfCaptureKind = selfCaptureKind
        super.init(configuration: configuration, file: file, scope: scope)
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
        if !hasSeenDeclaration(for: node.declName.baseName.text), node.isBaseSelf, isSelfRedundant {
            violations.append(
                at: node.positionAfterSkippingLeadingTrivia,
                correction: .init(
                    start: node.positionAfterSkippingLeadingTrivia,
                    end: node.period.endPositionBeforeTrailingTrivia,
                    replacement: ""
                )
            )
        }
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        // Will be handled separately by the parent visitor.
        .skipChildren
    }

    var isSelfRedundant: Bool {
           typeDeclKind == .likeStruct
        || functionCallType == .anonymousClosure
        || selfCaptureKind == .strong && SwiftVersion.current >= .fiveDotThree
        || selfCaptureKind == .weak && SwiftVersion.current >= .fiveDotEight
    }
}
