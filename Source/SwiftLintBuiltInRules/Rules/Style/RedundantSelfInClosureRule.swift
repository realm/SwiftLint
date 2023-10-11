import SwiftSyntax

struct RedundantSelfInClosureRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description = RuleDescription(
        identifier: "redundant_self_in_closure",
        name: "Redundant Self in Closure",
        description: "Explicit use of 'self' is not required",
        kind: .style,
        nonTriggeringExamples: RedundantSelfInClosureRuleExamples.nonTriggeringExamples,
        triggeringExamples: RedundantSelfInClosureRuleExamples.triggeringExamples,
        corrections: RedundantSelfInClosureRuleExamples.corrections
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        ContextVisitor()
    }
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
    final class ContextVisitor: DeclaredIdentifiersTrackingVisitor {
        private var typeDeclarations = Stack<TypeDeclarationKind>()
        private var functionCalls = Stack<FunctionCallType>()
        private var selfCaptures = Stack<SelfCaptureKind>()

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .extensionsAndProtocols }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeClass)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            typeDeclarations.pop()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeClass)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
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
                typeDeclarationKind: activeTypeDeclarationKind,
                functionCallType: activeFunctionCallType,
                selfCaptureKind: activeSelfCaptureKind,
                scope: scope
            ).walk(tree: node.statements, handler: \.violationCorrections)
            violations.append(contentsOf: localViolationCorrections.map(\.start))
            violationCorrections.append(contentsOf: localViolationCorrections)
            selfCaptures.pop()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeStruct)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
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

        override func visitPost(_ node: FunctionCallExprSyntax) {
            functionCalls.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeStruct)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            typeDeclarations.pop()
        }
    }
}

private class ExplicitSelfVisitor: DeclaredIdentifiersTrackingVisitor {
    private let typeDeclKind: TypeDeclarationKind
    private let functionCallType: FunctionCallType
    private let selfCaptureKind: SelfCaptureKind

    init(typeDeclarationKind: TypeDeclarationKind,
         functionCallType: FunctionCallType,
         selfCaptureKind: SelfCaptureKind,
         scope: Scope) {
        self.typeDeclKind = typeDeclarationKind
        self.functionCallType = functionCallType
        self.selfCaptureKind = selfCaptureKind
        super.init(scope: scope)
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
        if !hasSeenDeclaration(for: node.declName.baseName.text), node.isBaseSelf, isSelfRedundant {
            violationCorrections.append(
                ViolationCorrection(
                    start: node.positionAfterSkippingLeadingTrivia,
                    end: node.period.endPositionBeforeTrailingTrivia,
                    replacement: ""
                )
            )
        }
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
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
