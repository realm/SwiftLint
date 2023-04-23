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
                            guard let self = self ?? C() else { return }
                            self?.x = 1
                        }
                        C().f { self.x = 1 }
                        f { [weak self] in if let self { x = 1 } }
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
        ] + triggeringCompilerSpecificExamples,
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

#if compiler(>=5.8)
    private static let triggeringCompilerSpecificExamples = [
        Example("""
            class C {
                var x = 0
                func f(_ work: @escaping () -> Void) { work() }
                func g() {
                    f { [weak self] in
                        self?.x = 1
                        guard let self else { return }
                        ↓self.x = 1
                    }
                    f { [weak self] in
                        self?.x = 1
                        if let self = self else { ↓self.x = 1 }
                        self?.x = 1
                    }
                    f { [weak self] in
                        self?.x = 1
                        while let self else { ↓self.x = 1 }
                        self?.x = 1
                    }
                }
            }
        """)
    ]
#else
    private static let triggeringCompilerSpecificExamples = [Example]()
#endif

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
            selfCaptureKind: activeSelfCaptureKind
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

private class ExplicitSelfVisitor: ViolationsSyntaxVisitor {
    private let typeDeclKind: TypeDeclarationKind
    private let functionCallType: FunctionCallType
    private let selfCaptureKind: SelfCaptureKind

    private(set) var corrections = [(start: AbsolutePosition, end: AbsolutePosition)]()

    init(typeDeclarationKind: TypeDeclarationKind,
         functionCallType: FunctionCallType,
         selfCaptureKind: SelfCaptureKind) {
        self.typeDeclKind = typeDeclarationKind
        self.functionCallType = functionCallType
        self.selfCaptureKind = selfCaptureKind
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: MemberAccessExprSyntax) {
        if node.base?.as(IdentifierExprSyntax.self)?.isSelf == true, isSelfRedundant {
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
        if typeDeclKind == .likeStruct || functionCallType == .anonymousClosure {
            return true
        }
        if selfCaptureKind == .strong && SwiftVersion.current >= .fiveDotThree {
            return true
        }
        if selfCaptureKind == .weak && SwiftVersion.current >= .fiveDotEight {
            return true
        }
        return false
    }
}
