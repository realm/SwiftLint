import SwiftSyntax

struct RedundantSelfInClosureRule: SwiftSyntaxRule, CorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    static var description = RuleDescription(
        identifier: "redundant_self_in_closure",
        name: "Redundant Self in Closure",
        description: "Explicit use of 'self' is not required",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                struct S {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f {
                            x = 1
                            f { x = 1 }
                            g()
                        }
                    }
                }
            """),
            Example("""
                class C {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f { [weak self] in
                            self?.x = 1
                            self?.g()
                        }
                        C().f { self.x = 1 }
                        f { [weak self] in if let self { self.x = 1 } }
                    }
                }
            """)
        ],
        triggeringExamples: [
            Example("""
                struct S {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f {
                            ↓self.x = 1
                            if ↓self.x == 1 { ↓self.g() }
                        }
                    }
                }
            """),
            Example("""
                class C {
                    var x = 0
                    func g() {
                        {
                            ↓self.x = 1
                            ↓self.g()
                        }()
                    }
                }
            """),
            Example("""
                class C {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f { [self] in
                            ↓self.x = 1
                            ↓self.g()
                            f { self.x = 1 }
                        }
                    }
                }
            """),
            Example("""
                class C {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f { [unowned self] in ↓self.x = 1 }
                        f { [self = self] in ↓self.x = 1 }
                        f { [s = self] in s.x = 1 }
                    }
                }
            """)
        ],
        corrections: [
            Example("""
                struct S {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f {
                            ↓self.x = 1
                            if ↓self.x == 1 { ↓self.g() }
                        }
                    }
                }
            """): Example("""
                struct S {
                    var x = 0
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f {
                            x = 1
                            if x == 1 { g() }
                        }
                    }
                }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        ScopeVisitor(viewMode: .sourceAccurate)
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let ranges = ScopeVisitor(viewMode: .sourceAccurate)
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

private class ScopeVisitor: ViolationsSyntaxVisitor {
    private var typeDeclarations = [TypeDeclarationKind]()
    private var functionCalls = [FunctionCallType]()
    private var selfCaptures = [SelfCaptureKind]()

    private(set) var corrections = [(start: AbsolutePosition, end: AbsolutePosition)]()

    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .extensionsAndProtocols }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        typeDeclarations.append(.likeClass)
        return .visitChildren
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        _ = typeDeclarations.popLast()
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        typeDeclarations.append(.likeClass)
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        _ = typeDeclarations.popLast()
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        if let selfItem = node.signature?.capture?.items?.first(where: \.capturesSelf) {
            selfCaptures.append(selfItem.capturesWeakly ? .weak : .strong)
        } else {
            selfCaptures.append(.uncaptured)
        }
        return .visitChildren
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        guard let activeTypeDeclarationKind = typeDeclarations.last,
              let activeFunctionCallType = functionCalls.last,
              let activeSelfCaptureKind = selfCaptures.last else {
            return
        }
        let localCorrections = ExplicitSelfVisitor(
            typeDeclarationKind: activeTypeDeclarationKind,
            functionCallType: activeFunctionCallType,
            selfCaptureKind: activeSelfCaptureKind
        ).walk(tree: node.statements, handler: \.corrections)
        violations.append(contentsOf: localCorrections.map(\.start))
        corrections.append(contentsOf: localCorrections)
        _ = selfCaptures.popLast()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        typeDeclarations.append(.likeStruct)
        return .visitChildren
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        _ = typeDeclarations.popLast()
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if node.calledExpression.is(ClosureExprSyntax.self) {
            functionCalls.append(.anonymousClosure)
        } else {
            functionCalls.append(.function)
        }
        return .visitChildren
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
        _ = functionCalls.popLast()
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        typeDeclarations.append(.likeStruct)
        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) {
        _ = typeDeclarations.popLast()
    }
}

private class ExplicitSelfVisitor: ViolationsSyntaxVisitor {
    private let typeDeclarationKind: TypeDeclarationKind
    private let functionCallType: FunctionCallType
    private let selfCaptureKind: SelfCaptureKind

    private(set) var corrections = [(start: AbsolutePosition, end: AbsolutePosition)]()

    init(typeDeclarationKind: TypeDeclarationKind,
         functionCallType: FunctionCallType,
         selfCaptureKind: SelfCaptureKind) {
        self.typeDeclarationKind = typeDeclarationKind
        self.functionCallType = functionCallType
        self.selfCaptureKind = selfCaptureKind
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
        guard node.isSelfAccess else {
            return
        }
        if typeDeclarationKind == .likeStruct || functionCallType == .anonymousClosure || selfCaptureKind == .strong {
            corrections.append(
                (start: node.positionAfterSkippingLeadingTrivia, end: node.dot.endPositionBeforeTrailingTrivia)
            )
        }
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        // Will be handled separately by the parent visitor.
        .skipChildren
    }
}
