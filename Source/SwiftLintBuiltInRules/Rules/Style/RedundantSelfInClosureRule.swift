@_spi(Diagnostics)
import SwiftParser
@_spi(RawSyntax)
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
    case likeStruct, likeClass
}

private enum FunctionCallType {
    case anonymousClosure, function
}

private enum SelfCaptureKind {
    case strong, weak, uncaptured
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
            if node.keyPathInParent == \FunctionCallExprSyntax.calledExpression {
                functionCalls.push(.anonymousClosure)
            } else {
                functionCalls.push(.function)
            }
            return .visitChildren
        }

        override func visitPost(_: ClosureExprSyntax) {
            selfCaptures.pop()
            functionCalls.pop()
        }

        override func visit(_: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            typeDeclarations.push(.likeStruct)
            return .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            typeDeclarations.pop()
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            if selfCaptures.isNotEmpty {
                // In closure ...
                guard typeDeclarations.isNotEmpty, functionCalls.isNotEmpty, isSelfRedundant else {
                    return
                }
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
               typeDeclarations.peek() == .likeStruct
            || functionCalls.peek() == .anonymousClosure
            || selfCaptures.peek() == .strong && SwiftVersion.current >= .fiveDotThree
            || selfCaptures.peek() == .weak && SwiftVersion.current >= .fiveDotEight
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
