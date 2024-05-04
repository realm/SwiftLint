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
                deinit {}
            }
            """),
            Example("""
            public extension A {}
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
            // Violation marker is on `static` keyword
            Example("""
            /// a doc
            public class C {
                public ↓static let i = 1
            }
            """),
            // `excludes_extensions` only excludes the extension declaration itself; not its children
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
            """)
        ]
    )
}

private extension MissingDocsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.actorKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            collectViolation(from: node, on: node.associatedtypeKeyword)
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.classKeyword)
            return .visitChildren
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
            let acl = enumDecl.modifiers.accessibility ?? .internal
            node.elements.forEach {
                if let parameter = configuration.parameters.first(where: { $0.value == acl }) {
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
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.enumKeyword)
            return .visitChildren
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            if configuration.excludesExtensions {
                return .visitChildren
            }
            collectViolation(from: node, on: node.extensionKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            collectViolation(from: node, on: node.funcKeyword)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if node.signature.parameterClause.parameters.isEmpty, configuration.excludesTrivialInit {
                return
            }
            collectViolation(from: node, on: node.initKeyword)
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.protocolKeyword)
            return .visitChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            }
            collectViolation(from: node, on: node.structKeyword)
            return .visitChildren
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            collectViolation(from: node, on: node.subscriptKeyword)
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            collectViolation(from: node, on: node.typealiasKeyword)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            collectViolation(from: node, on: node.bindingSpecifier)
        }

        private func collectViolation(from node: some WithModifiersSyntax, on token: TokenSyntax) {
            if node.modifiers.contains(keyword: .override) || node.hasDocComment {
                return
            }
            if node.parent?.is(MemberBlockItemSyntax.self) != true, node.parentDeclGroup != nil {
                // Declaration is not a member item but within another declaration. Nested declarations are implicitly
                // hidden, hence don't require documentation.
                return
            }
            let acl = node.modifiers.accessibility ?? node.defaultAccessibility
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
