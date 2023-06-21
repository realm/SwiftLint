import SwiftSyntax

struct RedundantSelfInClosureRule: SwiftSyntaxRule, CorrectableRule, ConfigurationProviderRule, OptInRule {
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

    func correct(file: SwiftLintFile) -> [Correction] {
        let ranges = ContextVisitor()
            .walk(file: file, handler: \.corrections)
            .compactMap { file.stringView.NSRange(start: $0.start, end: $0.end) }
            .filter { file.ruleEnabled(violatingRange: $0, for: self) != nil }
            .reversed()

        var corrections = [Correction]()
        var contents = file.contents
        for range in ranges {
            let contentsNSString = contents.bridge()
            contents = contentsNSString.replacingCharacters(in: range, with: "")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: Self.description, location: location))
        }

        file.write(contents)

        return corrections
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

private class ContextVisitor: DeclaredIdentifiersTrackingVisitor {
    private var typeDeclarations = Stack<TypeDeclarationKind>()
    private var functionCalls = Stack<FunctionCallType>()
    private var selfCaptures = Stack<SelfCaptureKind>()

    private(set) var corrections = [(start: AbsolutePosition, end: AbsolutePosition)]()

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
        if let selfItem = node.signature?.capture?.items?.first(where: \.capturesSelf) {
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
        let localCorrections = ExplicitSelfVisitor(
            typeDeclarationKind: activeTypeDeclarationKind,
            functionCallType: activeFunctionCallType,
            selfCaptureKind: activeSelfCaptureKind,
            scope: scope
        ).walk(tree: node.statements, handler: \.corrections)
        violations.append(contentsOf: localCorrections.map(\.start))
        corrections.append(contentsOf: localCorrections)
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

private class ExplicitSelfVisitor: DeclaredIdentifiersTrackingVisitor {
    private let typeDeclKind: TypeDeclarationKind
    private let functionCallType: FunctionCallType
    private let selfCaptureKind: SelfCaptureKind

    private(set) var corrections = [(start: AbsolutePosition, end: AbsolutePosition)]()

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
        if !hasSeenDeclaration(for: node.name.text), node.isBaseSelf, isSelfRedundant {
            corrections.append(
                (start: node.positionAfterSkippingLeadingTrivia, end: node.dot.endPositionBeforeTrailingTrivia)
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
