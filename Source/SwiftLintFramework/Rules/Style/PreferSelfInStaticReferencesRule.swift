import SwiftSyntax

struct PreferSelfInStaticReferencesRule: SwiftSyntaxRule, CorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "prefer_self_in_static_references",
        name: "Prefer Self in Static References",
        description: "Use `Self` to refer to the surrounding type name",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                class C {
                    static let primes = [2, 3, 5, 7]
                    func isPrime(i: Int) -> Bool { Self.primes.contains(i) }
            """),
            Example("""
                struct T {
                    static let i = 0
                }
                struct S {
                    static let i = 0
                }
                extension T {
                    static let j = S.i + T.i
                    static let k = { T.j }()
                }
            """),
            Example("""
                class `Self` {
                    static let i = 0
                    func f() -> Int { Self.i }
                }
            """),
            Example("""
                class C {
                    static private(set) var i = 0, j = C.i
                    static let k = { C.i }()
                    let h = C.i
                    @GreaterThan(C.j) var k: Int
                    func f() {
                        _ = [Int: C]()
                        _ = [C]()
                    }
                }
            """, excludeFromDocumentation: true),
            Example("""
                struct S {
                    struct T {
                        struct R {
                            static let i = 3
                        }
                    }
                    struct R {
                        static let j = S.T.R.i
                    }
                    static let j = Self.T.R.i + Self.R.j
                    let h = Self.T.R.i + Self.R.j
                }
            """, excludeFromDocumentation: true),
            Example("""
                class C {
                    static let s = 2
                    func f(i: Int = C.s) -> Int {
                        func g(@GreaterEqualThan(C.s) j: Int = C.s) -> Int { j }
                        return i + Self.s
                    }
                    func g() -> Any { C.self }
                }
            """, excludeFromDocumentation: true),
            Example("""
                class Record<T> {
                    static func get() -> Record<T> { Record<T>() }
                }
            """, excludeFromDocumentation: true),
            Example("""
                @objc class C: NSObject {
                    @objc var s = ""
                    @objc func f() { _ = #keyPath(C.s) }
                }
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("""
            final class CheckCellView: NSTableCellView {
              @IBOutlet var checkButton: NSButton!

              override func awakeFromNib() {
                checkButton.action = #selector(↓CheckCellView.check(_:))
              }

              @objc func check(_ button: AnyObject?) {}
            }
            """),
            Example("""
                class C {
                    struct S {
                        static let i = 2
                        let h = ↓S.i
                    }
                    static let i = 1
                    let h = C.i
                    var j: Int { ↓C.i }
                    func f() -> Int { ↓C.i + h }
                }
            """),
            Example("""
                struct S {
                    let j: Int
                    static let i = 1
                    static func f() -> Int { ↓S.i }
                    func g() -> Any { ↓S.self }
                    func h() -> S { ↓S(j: 2) }
                    func i() -> KeyPath<S, Int> { \\↓S.j }
                    func j(@Wrap(-↓S.i, ↓S.i) n: Int = ↓S.i) {}
                }
            """),
            Example("""
                struct S {
                    struct T {
                        static let i = 3
                    }
                    struct R {
                        static let j = S.T.i
                    }
                    static let h = ↓S.T.i + ↓S.R.j
                }
            """),
            Example("""
                enum E {
                    case A
                    static func f() -> E { ↓E.A }
                    static func g() -> E { ↓E.f() }
                }
            """),
            Example("""
                extension E {
                    class C {
                        static var i = 2
                        var j: Int { ↓C.i }
                        var k: Int {
                            get { ↓C.i }
                            set { ↓C.i = newValue }
                        }
                    }
                }
            """, excludeFromDocumentation: true),
            Example("""
                class C {
                    var c: C { C() }
                }
                final class D {
                    var d: D { ↓D() }
                }
            """, excludeFromDocumentation: true)
        ],
        corrections: [
            Example("""
            final class CheckCellView: NSTableCellView {
              @IBOutlet var checkButton: NSButton!

              override func awakeFromNib() {
                checkButton.action = #selector(↓CheckCellView.check(_:))
              }

              @objc func check(_ button: AnyObject?) {}
            }
            """):
                Example("""
                final class CheckCellView: NSTableCellView {
                  @IBOutlet var checkButton: NSButton!

                  override func awakeFromNib() {
                    checkButton.action = #selector(Self.check(_:))
                  }

                  @objc func check(_ button: AnyObject?) {}
                }
                """),
            Example("""
                struct S {
                    static let i = 1
                    static let j = ↓S.i
                    let k = ↓S  . j
                    static func f(_ l: Int = ↓S.i) -> Int { l*↓S.j }
                    func g() { ↓S.i + ↓S.f() + k }
                }
            """): Example("""
                struct S {
                    static let i = 1
                    static let j = Self.i
                    let k = Self  . j
                    static func f(_ l: Int = Self.i) -> Int { l*Self.j }
                    func g() { Self.i + Self.f() + k }
                }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let ranges = Visitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.corrections)
            .compactMap { file.stringView.NSRange(start: $0.start, end: $0.end) }
            .filter { file.ruleEnabled(violatingRange: $0, for: self) != nil }
            .reversed()

        var corrections = [Correction]()
        var contents = file.contents
        for range in ranges {
            let contentsNSString = contents.bridge()
            contents = contentsNSString.replacingCharacters(in: range, with: "Self")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: Self.description, location: location))
        }

        file.write(contents)

        return corrections
    }
}

private class Visitor: ViolationsSyntaxVisitor {
    private enum ParentDeclBehavior {
        case likeClass(name: String, isFinal: Bool)
        case likeStruct(String)
        case skipReferences

        var parentName: String? {
            switch self {
            case let .likeClass(name, _): return name
            case let .likeStruct(name): return name
            case .skipReferences: return nil
            }
        }
    }

    private enum VariableDeclBehavior {
        case handleReferences
        case skipReferences
    }

    private var parentDeclScopes = [ParentDeclBehavior]()
    private var variableDeclScopes = [VariableDeclBehavior]()
    private(set) var corrections = [(start: AbsolutePosition, end: AbsolutePosition)]()

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.append(.likeClass(name: node.identifier.text, isFinal: node.modifiers.isFinal))
        return .skipChildren
    }

    override func visitPost(_ node: ActorDeclSyntax) {
        _ = parentDeclScopes.popLast()
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.append(.likeClass(name: node.identifier.text, isFinal: node.modifiers.isFinal))
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        _ = parentDeclScopes.popLast()
    }

    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        variableDeclScopes.append(.handleReferences)
        return .visitChildren
    }

    override func visitPost(_ node: CodeBlockSyntax) {
        _ = variableDeclScopes.popLast()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.append(.likeStruct(node.identifier.text))
        return .visitChildren
    }

    override func visitPost(_ node: EnumDeclSyntax) {
        _ = parentDeclScopes.popLast()
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.append(.skipReferences)
        return .visitChildren
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        _ = parentDeclScopes.popLast()
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if case .likeClass = parentDeclScopes.last {
            if node.name.tokenKind == .keyword(.self) {
                return .skipChildren
            }
        }
        return .visitChildren
    }

    override func visitPost(_ node: IdentifierExprSyntax) {
        guard let parent = node.parent,
              parent.as(SpecializeExprSyntax.self) == nil,
              parent.as(DictionaryElementSyntax.self) == nil,
              parent.as(ArrayElementSyntax.self) == nil else {
            return
        }
        if parent.as(FunctionCallExprSyntax.self) != nil, case .likeClass(_, false) = parentDeclScopes.last {
            return
        }
        addViolation(on: node.identifier)
    }

    override func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
        if case .likeClass = parentDeclScopes.last {
            variableDeclScopes.append(.skipReferences)
        } else {
            variableDeclScopes.append(.handleReferences)
        }
        return .visitChildren
    }

    override func visitPost(_ node: MemberDeclBlockSyntax) {
        _ = variableDeclScopes.popLast()
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        if case .likeClass = parentDeclScopes.last, case .identifier("selector") = node.macro.tokenKind {
            return .visitChildren
        }
        return .skipChildren
    }

    override func visit(_ node: ParameterClauseSyntax) -> SyntaxVisitorContinueKind {
        if case .likeStruct = parentDeclScopes.last {
            return .visitChildren
        }
        return .skipChildren
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.append(.skipReferences)
        return .skipChildren
    }

    override func visitPost(_ node: ProtocolDeclSyntax) {
        _ = parentDeclScopes.popLast()
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        parentDeclScopes.append(.likeStruct(node.identifier.text))
        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) {
        _ = parentDeclScopes.popLast()
    }

    override func visitPost(_ node: SimpleTypeIdentifierSyntax) {
        if node.parent?.as(KeyPathExprSyntax.self) != nil {
            addViolation(on: node.name)
        }
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.bindings.onlyElement?.accessor != nil {
            // Computed property
            return .visitChildren
        }
        if case .handleReferences = variableDeclScopes.last {
            return .visitChildren
        }
        return .skipChildren
    }

    private func addViolation(on node: TokenSyntax) {
        if let parentName = parentDeclScopes.last?.parentName, node.tokenKind == .identifier(parentName) {
            violations.append(node.positionAfterSkippingLeadingTrivia)
            corrections.append(
                (start: node.positionAfterSkippingLeadingTrivia, end: node.endPositionBeforeTrailingTrivia)
            )
        }
    }
}
