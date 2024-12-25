import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct StrictFilePrivateRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "strict_fileprivate",
        name: "Strict Fileprivate",
        description: "`fileprivate` should be avoided",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("extension String {}"),
            Example("private extension String {}"),
            Example("""
            public
                extension String {
                    var i: Int { 1 }
                }
            """),
            Example("""
                private enum E {
                    func f() {}
                }
            """),
            Example("""
                public struct S {
                    internal let i: Int
                }
            """),
            Example("""
                open class C {
                    private func f() {}
                }
            """),
            Example("""
                internal actor A {}
            """),
            Example("""
                struct S1: P {
                    fileprivate let i = 2, j = 1
                }
                struct S2: P {
                    fileprivate var (k, l) = (1, 3)
                }
                protocol P {
                    var j: Int { get }
                    var l: Int { get }
                }
            """, excludeFromDocumentation: true),
            Example("""
                class C: P<Int> {
                    fileprivate func f() {}
                }
                protocol P<T> {
                    func f()
                }
            """, excludeFromDocumentation: true),
        ] + ["actor", "class", "enum", "extension", "struct"].map { type in
            Example("""
                \(type) T: P<Int> {
                    fileprivate func f() {}
                    fileprivate let i = 3
                    public fileprivate(set) var l = 3
                }
                protocol P<T> {
                    func f()
                    var i: Int { get }
                    var l: Int { get set }
                }
            """, excludeFromDocumentation: true)
        },
        triggeringExamples: [
            Example("""
                ↓fileprivate class C {
                    ↓fileprivate func f() {}
                }
            """),
            Example("""
                ↓fileprivate extension String {
                    ↓fileprivate var isSomething: Bool { self == "something" }
                }
            """),
            Example("""
                ↓fileprivate actor A {
                    ↓fileprivate let i = 1
                }
            """),
            Example("""
                ↓fileprivate struct C {
                    ↓fileprivate(set) var myInt = 4
                }
            """),
            Example("""
                struct Outter {
                    struct Inter {
                        ↓fileprivate struct Inner {}
                    }
                }
            """),
            Example("""
                ↓fileprivate func f() {}
            """, excludeFromDocumentation: true),
        ] + ["actor", "class", "enum", "extension", "struct"].map { type in
            Example("""
                \(type) T: P<Int> {
                    fileprivate func f() {}
                    ↓fileprivate func g() {}
                    fileprivate let i = 2
                    public ↓fileprivate(set) var j: Int { 1 }
                    ↓fileprivate let a = 3, b = 4
                    public ↓fileprivate(set) var k = 2
                }
                protocol P<T> {
                    func f()
                    var i: Int { get }
                    var k: Int { get }
                }
                protocol Q {
                    func g()
                    var j: Int { get }
                }
            """, excludeFromDocumentation: true)
        }
    )
}

private enum ProtocolRequirementType: Equatable {
    case method(String)
    case getter(String)
    case setter(String)
}

private extension StrictFilePrivateRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private lazy var protocols = {
            ProtocolCollector(configuration: configuration, file: file)
                .walk(tree: file.syntaxTree, handler: \.protocols)
        }()

        override func visitPost(_ node: DeclModifierSyntax) {
            guard node.name.tokenKind == .keyword(.fileprivate), let grandparent = node.parent?.parent else {
                return
            }
            guard grandparent.is(FunctionDeclSyntax.self) || grandparent.is(VariableDeclSyntax.self) else {
                violations.append(node.positionAfterSkippingLeadingTrivia)
                return
            }
            let protocolMethodNames = implementedTypesInDecl(of: node).flatMap { protocols[$0, default: []] }
            if let funcDecl = grandparent.as(FunctionDeclSyntax.self),
               protocolMethodNames.contains(.method(funcDecl.name.text)) {
                return
            }
            if let varDecl = grandparent.as(VariableDeclSyntax.self) {
                let isSpecificForSetter = node.detail?.detail.tokenKind == .identifier("set")
                let firstImplementingProtocol = varDecl.bindings
                    .flatMap { binding in
                        let pattern = binding.pattern
                        if let name = pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                            return [name]
                        }
                        if let tuple = pattern.as(TuplePatternSyntax.self) {
                            return tuple.elements.compactMap {
                                $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                            }
                        }
                        return []
                    }
                    .first {
                        protocolMethodNames.contains(isSpecificForSetter ? .setter($0) : .getter($0))
                    }
                if firstImplementingProtocol != nil {
                    return
                }
            }
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }

        private func implementedTypesInDecl(of node: (some SyntaxProtocol)?) -> [String] {
            guard let node else {
                queuedFatalError("Given node is nil. That should not happen.")
            }
            if node.is(SourceFileSyntax.self) {
                return []
            }
            if let actorDecl = node.as(ActorDeclSyntax.self) {
                return actorDecl.inheritanceClause.inheritedTypeNames
            }
            if let classDecl = node.as(ClassDeclSyntax.self) {
                return classDecl.inheritanceClause.inheritedTypeNames
            }
            if let enumDecl = node.as(EnumDeclSyntax.self) {
                return enumDecl.inheritanceClause.inheritedTypeNames
            }
            if let extensionDecl = node.as(ExtensionDeclSyntax.self) {
                return extensionDecl.inheritanceClause.inheritedTypeNames
            }
            if let structDecl = node.as(StructDeclSyntax.self) {
                return structDecl.inheritanceClause.inheritedTypeNames
            }
            return implementedTypesInDecl(of: node.parent)
        }
    }
}

private final class ProtocolCollector<Configuration: RuleConfiguration>: ViolationsSyntaxVisitor<Configuration> {
    private(set) var protocols = [String: [ProtocolRequirementType]]()
    private var currentProtocolName = ""

    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .allExcept(ProtocolDeclSyntax.self) }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        currentProtocolName = node.name.text
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        protocols[currentProtocolName, default: []].append(.method(node.name.text))
        return .skipChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let accessorBlock = binding.accessorBlock else {
                continue
            }
            if accessorBlock.specifiesGetAccessor {
                protocols[currentProtocolName, default: []].append(.getter(name))
            }
            if accessorBlock.specifiesSetAccessor {
                protocols[currentProtocolName, default: []].append(.setter(name))
            }
        }
        return .skipChildren
    }
}

private extension InheritanceClauseSyntax? {
    var inheritedTypeNames: [String] {
        self?.inheritedTypes.compactMap { $0.type.as(IdentifierTypeSyntax.self)?.name.text } ?? []
    }
}
