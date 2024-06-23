import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct MissingDocsRule: OptInRule {
    var configuration = MissingDocsConfiguration()

    static let description = RuleDescription(
        identifier: "missing_docs",
        name: "Missing Docs",
        description: "Declarations should be documented.",
        kind: .lint,
        nonTriggeringExamples: [
            // locally-defined superclass member is documented, but subclass member is not
            Example("""
            /// docs
            public class A {
            /// docs
            public func b() {}
            }
            // no docs
            public class B: A { override public func b() {} }
            """),
            // externally-defined superclass member is documented, but subclass member is not
            Example("""
            import Foundation
            // no docs
            public class B: NSObject {
            // no docs
            override public var description: String { fatalError() } }
            """),
            Example("""
            /// docs
            public class A {
                var j = 1
                var i: Int { 1 }
                func f() {}
                deinit {}
            }
            """),
            Example("""
            public extension A {}
            """),
            Example("""
            enum E {
                case A
            }
            """),
            Example("""
            /// docs
            public class A {
                public init() {}
            }
            """, configuration: ["excludes_trivial_init": true]),
        ],
        triggeringExamples: [
            // public, undocumented
            Example("public ↓func a() {}"),
            // public, undocumented
            Example("// regular comment\npublic ↓func a() {}"),
            // public, undocumented
            Example("/* regular comment */\npublic ↓func a() {}"),
            // protocol member and inherited member are both undocumented
            Example("""
            /// docs
            public protocol A {
                // no docs
                ↓var b: Int { get }
            }
            /// docs
            public struct C: A {
                public let b: Int
            }
            """),
            // Violation marker is on `static` keyword.
            Example("""
            /// a doc
            public class C {
                public ↓static let i = 1
            }
            """),
            // `excludes_extensions` only excludes the extension declaration itself; not its children.
            Example("""
            public extension A {
                public ↓func f() {}
            }
            """),
            Example("""
            /// docs
            public class A {
                public ↓init(argument: String) {}
            }
            """, configuration: ["excludes_trivial_init": true]),
            Example("""
            public ↓struct C: A {
                public ↓let b: Int
            }
            """, configuration: ["excludes_inherited_types": false]),
            Example("""
            public ↓extension A {
                public ↓func f() {}
            }
            """, configuration: ["excludes_extensions": false]),
            Example("""
            public extension E {
                ↓var i: Int {
                    let j = 1
                    func f() {}
                    return j
                }
            }
            """),
            Example("""
            #if os(macOS)
            public ↓func f() {}
            #endif
            """),
            Example("""
            public ↓enum E {
                case ↓A
                func f() {}
                init(_ i: Int) { self = .A }
            }
            """),
            Example("""
            open ↓class C {
                public ↓enum E {
                    case ↓A
                    func f() {}
                    init(_ i: Int) { self = .A }
                }
            }
            """, excludeFromDocumentation: true),
            /// Nested types inherit the ACL from the declaring extension.
            Example("""
            /// a doc
            public struct S {}
            public extension S {
                ↓enum E {
                    case ↓A
                }
            }
            """)
        ]
    )
}

private extension MissingDocsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var aclScope = Stack<AccessControlBehavior>()

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            defer { aclScope.push(node.modifiers.accessibility) }
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.actorKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            aclScope.pop()
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            collectViolation(from: node, on: node.associatedtypeKeyword)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            defer { aclScope.push(node.modifiers.accessibility) }
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.classKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visitPost(_ node: EnumCaseDeclSyntax) {
            guard !node.hasDocComment, let enumDecl = node.parentDeclGroup?.as(EnumDeclSyntax.self) else {
                return
            }
            let acl = enumDecl.modifiers.accessibility
                ?? enumDecl.parentDeclGroup?.as(ExtensionDeclSyntax.self)?.modifiers.accessibility
                ?? .internal
            if let parameter = configuration.parameters.first(where: { $0.value == acl }) {
                node.elements.forEach {
                    violations.append(
                        ReasonedRuleViolation(
                            position: $0.name.positionAfterSkippingLeadingTrivia,
                            reason: "\(acl) declarations should be documented",
                            severity: parameter.severity
                        )
                    )
                }
            }
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            defer { aclScope.push(node.modifiers.accessibility) }
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.enumKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            defer { aclScope.push(node.modifiers.accessibility, appliesToChildren: true) }
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            if configuration.excludesExtensions {
                return .visitChildren
            }
            collectViolation(from: node, on: node.extensionKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolation(from: node, on: node.funcKeyword)
            return .skipChildren
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.signature.parameterClause.parameters.isNotEmpty || !configuration.excludesTrivialInit {
                collectViolation(from: node, on: node.initKeyword)
            }
            return .skipChildren
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            defer { aclScope.push(node.modifiers.accessibility, appliesToChildren: true) }
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.protocolKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            defer { aclScope.push(node.modifiers.accessibility) }
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.structKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            aclScope.pop()
        }

        override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolation(from: node, on: node.subscriptKeyword)
            return .skipChildren
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            collectViolation(from: node, on: node.typealiasKeyword)
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolation(from: node, on: node.bindingSpecifier)
            return .skipChildren
        }

        private func collectViolation(from node: some WithModifiersSyntax, on token: TokenSyntax) {
            if node.modifiers.contains(keyword: .override) || node.hasDocComment {
                return
            }
            let acl = aclScope.computeAcl(givenExplicitAcl: node.modifiers.accessibility)
            if let parameter = configuration.parameters.first(where: { $0.value == acl }) {
                violations.append(
                    ReasonedRuleViolation(
                        position: (node.modifiers.staticOrClass ?? token).positionAfterSkippingLeadingTrivia,
                        reason: "\(acl) declarations should be documented",
                        severity: parameter.severity
                    )
                )
            }
        }
    }
}

private extension WithModifiersSyntax {
    var hasDocComment: Bool {
        switch leadingTrivia.pieces.last(where: { !$0.isWhitespace }) {
        case .docBlockComment, .docLineComment: true
        default: false
        }
    }
}

private extension SyntaxProtocol {
    var parentDeclGroup: (any DeclGroupSyntax)? {
        guard let parent else {
            return nil
        }
        if let declGroup = parent.asProtocol((any DeclGroupSyntax).self) {
            return declGroup
        }
        return parent.parentDeclGroup
    }

    var defaultAccessibility: AccessControlLevel {
        if let declGroup = parentDeclGroup,
           declGroup.is(ExtensionDeclSyntax.self) || declGroup.is(ProtocolDeclSyntax.self),
           let accessibility = declGroup.modifiers.accessibility {
            return accessibility
        }
        return .internal
    }
}

private extension DeclModifierListSyntax {
    var accessibility: AccessControlLevel? {
        filter { $0.detail == nil }.compactMap { AccessControlLevel(description: $0.name.text) }.first
    }

    var staticOrClass: TokenSyntax? {
        first { $0.name.text == "static" || $0.name.text == "class" }?.name
    }
}

private enum AccessControlBehavior {
    /// ACL as specified or inherited from the declaration's parent.
    case strict(AccessControlLevel)
    /// Internal visibility for declarations in otherwise public contexts.
    case impliedInternal
}

/// Implementation of Swift's effective ACL logic. Should be moved to a specialized syntax visitor for reuse some time.
private extension Stack<AccessControlBehavior> {
    mutating func push(_ acl: AccessControlLevel?, appliesToChildren: Bool = false) {
        if let parentBehavior = peek() {
            if case let .strict(parentAcl) = parentBehavior {
                if let acl, acl < parentAcl {
                    push(.strict(acl))
                } else {
                    push(.strict(parentAcl))
                }
            }
        }
        if let acl {
            push(appliesToChildren || acl < .public ? .strict(acl) : .impliedInternal)
        } else {
            push(.strict(.internal))
        }
    }

    func computeAcl(givenExplicitAcl acl: AccessControlLevel?) -> AccessControlLevel {
        switch peek() {
        case let .strict(parentAcl):
            if let acl, acl < parentAcl {
                acl
            } else {
                parentAcl
            }
        case .impliedInternal, .none:
            acl ?? .internal
        }
    }
}
