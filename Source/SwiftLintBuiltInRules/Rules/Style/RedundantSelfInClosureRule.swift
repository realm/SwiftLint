import SwiftSyntax

// swiftlint:disable file_length

struct RedundantSelfInClosureRule: SwiftSyntaxRule, CorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

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
            """),
            Example("""
                struct S {
                    var x = 0, error = 0, exception = 0
                    var y: Int?, z: Int?, u: Int, v: Int?, w: Int?
                    func f(_ work: @escaping (Int) -> Void) { work() }
                    func g(x: Int) {
                        f { u in
                            self.x = x
                            let x = 1
                            self.x = 2
                            if let y, let v {
                                self.y = 3
                                self.v = 1
                            }
                            guard let z else {
                                let v = 4
                                self.x = 5
                                self.v = 6
                                return
                            }
                            self.z = 7
                            while let v { self.v = 8 }
                            for w in [Int]() { self.w = 9 }
                            self.u = u
                            do {} catch { self.error = 10 }
                            do {} catch let exception { self.exception = 11 }
                        }
                    }
                }
            """),
            Example("""
                enum E {
                    case a(Int)
                    case b(Int, Int)
                }
                struct S {
                    var x: E = .a(3), y: Int, z: Int
                    func f(_ work: @escaping () -> Void) { work() }
                    func g(x: Int) {
                        f {
                            switch x {
                            case let .a(y):
                                self.y = 1
                            case .b(let y, var z):
                                self.y = 2
                                self.z = 3
                            }
                        }
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
            """),
            Example("""
                struct S {
                    var x = 0
                    var y: Int?, z: Int?, v: Int?, w: Int?
                    func f(_ work: @escaping () -> Void) { work() }
                    func g(w: Int, _ v: Int) {
                        f {
                            self.w = 1
                            ↓self.x = 2
                            if let y { ↓self.x = 3 }
                            else { ↓self.y = 3 }
                            guard let z else {
                                ↓self.z = 4
                                ↓self.x = 5
                                return
                            }
                            ↓self.y = 6
                            while let y { ↓self.x = 7 }
                            for y in [Int]() { ↓self.x = 8 }
                            self.v = 9
                            do {
                                let x = 10
                                self.x = 11
                            }
                            ↓self.x = 12
                        }
                    }
                }
            """),
            Example("""
                struct S {
                    func f(_ work: @escaping () -> Void) { work() }
                    func g() {
                        f { let g = ↓self.g() }
                    }
                }
            """, excludeFromDocumentation: true)
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

private extension MemberAccessExprSyntax {
    var isBaseSelf: Bool {
        base?.as(IdentifierExprSyntax.self)?.isSelf == true
    }
}
