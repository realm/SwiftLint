import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ExplicitACLRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "explicit_acl",
        name: "Explicit ACL",
        description: "All declarations should specify Access Control Level keywords explicitly",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("internal enum A {}"),
            Example("public final class B {}"),
            Example("private struct C {}"),
            Example("internal enum A { internal enum B {} }"),
            Example("internal final class Foo {}"),
            Example("""
            internal
            class Foo {
              private let bar = 5
            }
            """),
            Example("internal func a() { let a =  }"),
            Example("private func a() { func innerFunction() { } }"),
            Example("private enum Foo { enum Bar { } }"),
            Example("private struct C { let d = 5 }"),
            Example("""
            internal protocol A {
              func b()
            }
            """),
            Example("""
            internal protocol A {
              var b: Int
            }
            """),
            Example("internal class A { deinit {} }"),
            Example("extension A: Equatable {}"),
            Example("extension A {}"),
            Example("""
            extension Foo {
                internal func bar() {}
            }
            """),
            Example("""
            internal enum Foo {
                case bar
            }
            """),
            Example("""
            extension Foo {
                public var isValid: Bool {
                    let result = true
                    return result
                }
            }
            """),
            Example("""
            extension Foo {
                private var isValid: Bool {
                    get {
                        return true
                    }
                    set(newValue) {
                        print(newValue)
                    }
                }
            }
            """),
            Example("""
            private extension Foo {
                var isValid: Bool { true }
                struct S {
                    let b = 2
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("↓enum A {}"),
            Example("final ↓class B {}"),
            Example("internal struct C { ↓let d = 5 }"),
            Example("public struct C { private(set) ↓var d = 5 }"),
            Example("internal struct C { static ↓let d = 5 }"),
            Example("public struct C { ↓let d = 5 }"),
            Example("public struct C { ↓init() }"),
            Example("static ↓func a() {}"),
            Example("internal let a = 0\n↓func b() {}"),
            Example("""
            extension Foo {
                ↓func bar() {}
                static ↓func baz() {}
            }
            """),
            Example("""
            public extension E {
                let a = 1
                struct S {
                    ↓let b = 2
                }
            }
            """),
        ]
    )
}

private enum CheckACLState {
    case yes
    case no // swiftlint:disable:this identifier_name
}

private extension ExplicitACLRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var declScope = Stack<CheckACLState>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [
                FunctionDeclSyntax.self,
                SubscriptDeclSyntax.self,
                VariableDeclSyntax.self,
                ProtocolDeclSyntax.self,
                InitializerDeclSyntax.self,
            ]
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolations(decl: node, token: node.actorKeyword)
            declScope.push(.yes)
            return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
        }

        override func visitPost(_: ActorDeclSyntax) {
            declScope.pop()
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolations(decl: node, token: node.classKeyword)
            declScope.push(.yes)
            return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            declScope.pop()
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            declScope.push(node.modifiers.accessLevelModifier != nil ? .no : .yes)
            return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
        }

        override func visitPost(_: ExtensionDeclSyntax) {
            declScope.pop()
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolations(decl: node, token: node.enumKeyword)
            declScope.push(.yes)
            return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
        }

        override func visitPost(_: EnumDeclSyntax) {
            declScope.pop()
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            collectViolations(decl: node, token: node.funcKeyword)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            collectViolations(decl: node, token: node.initKeyword)
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            collectViolations(decl: node, token: node.protocolKeyword)
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            collectViolations(decl: node, token: node.structKeyword)
            declScope.push(.yes)
            return node.modifiers.containsPrivateOrFileprivate() ? .skipChildren : .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            declScope.pop()
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            collectViolations(decl: node, token: node.subscriptKeyword)
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            collectViolations(decl: node, token: node.typealiasKeyword)
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            collectViolations(decl: node, token: node.bindingSpecifier)
        }

        private func collectViolations(decl: some WithModifiersSyntax, token: TokenSyntax) {
            let aclModifiers = decl.modifiers.filter { $0.asAccessLevelModifier != nil }
            if declScope.peek() != .no, aclModifiers.isEmpty || aclModifiers.allSatisfy({ $0.detail != nil }) {
                violations.append(token.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
