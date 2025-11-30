@_spi(Diagnostics)
import SwiftParser
@_spi(RawSyntax)
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct RedundantSelfRule: Rule {
    var configuration = RedundantSelfConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_self",
        name: "Redundant Self",
        description: "Explicit use of 'self' is not required",
        kind: .style,
        nonTriggeringExamples: RedundantSelfRuleExamples.nonTriggeringExamples,
        triggeringExamples: RedundantSelfRuleExamples.triggeringExamples,
        corrections: RedundantSelfRuleExamples.corrections,
        deprecatedAliases: ["redundant_self_in_closure"]
    )
}

private enum TypeDeclarationKind {
    case likeStruct, likeClass
}

private enum ClosureExprType {
    case anonymousCall, functionArgument
}

private enum SelfCaptureKind {
    case strong, weak, uncaptured
}

private extension RedundantSelfRule {
    final class Visitor: DeclaredIdentifiersTrackingVisitor<ConfigurationType> {
        private var typeDeclarations = Stack<TypeDeclarationKind>()
        private var closureExprScopes = Stack<(ClosureExprType, SelfCaptureKind)>()
        private var initializerScopes = Stack<Bool>()

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
            let captureType: SelfCaptureKind =
                if let selfItem = node.signature?.capture?.items.first(where: \.capturesSelf) {
                    selfItem.capturesWeakly ? .weak : .strong
                } else {
                    .uncaptured
                }
            let exprType: ClosureExprType =
                if node.keyPathInParent == \FunctionCallExprSyntax.calledExpression {
                    .anonymousCall
                } else {
                    .functionArgument
                }
            closureExprScopes.push((exprType, captureType))
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            closureExprScopes.pop()
        }

        override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeStruct)
            return .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            typeDeclarations.pop()
        }

        override func visit(_: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            initializerScopes.push(true)
            return .visitChildren
        }

        override func visitPost(_: InitializerDeclSyntax) {
            initializerScopes.pop()
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            if configuration.keepInInitializers, initializerScopes.peek() == true {
                return
            }
            if closureExprScopes.isNotEmpty, !isSelfRedundant {
                return
            }
            let declName = node.declName.baseName.text
            if !hasSeenDeclaration(for: declName), node.isBaseSelf, declName != "init" {
                violations.append(
                    at: node.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: node.positionAfterSkippingLeadingTrivia,
                        end: node.endPositionBeforeTrailingTrivia,
                        replacement: node.declName.baseName.needsEscaping
                            ? "`\(declName)`"
                            : declName
                    )
                )
            }
        }

        override func visit(_: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeStruct)
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            typeDeclarations.pop()
        }

        private var isSelfRedundant: Bool {
            if typeDeclarations.peek() == .likeStruct {
                return true
            }
            guard let (closureType, selfCapture) = closureExprScopes.peek() else {
                return false
            }
            return closureType == .anonymousCall
                || selfCapture == .strong && SwiftVersion.current >= .fiveDotThree
                || selfCapture == .weak && SwiftVersion.current >= .fiveDotEight
        }
    }
}

private extension TokenSyntax {
    var needsEscaping: Bool {
        [UInt8](text.utf8).withUnsafeBufferPointer {
            if let keyword = Keyword(SyntaxText(baseAddress: $0.baseAddress, count: text.count)) {
                return TokenKind.keyword(keyword).isLexerClassifiedKeyword
            }
            return false
        }
    }
}
