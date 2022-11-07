import SwiftSyntax

public struct ExplicitACLRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_acl",
        name: "Explicit ACL",
        description: "All declarations should specify Access Control Level keywords explicitly.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("internal enum A {}\n"),
            Example("public final class B {}\n"),
            Example("private struct C {}\n"),
            Example("internal enum A {\n internal enum B {}\n}"),
            Example("internal final class Foo {}"),
            Example("""
            internal
            class Foo {
              private let bar = 5
            }
            """),
            Example("internal func a() { let a =  }\n"),
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
                var isValid: Bool {
                    true
                }
            }
            """)
        ],
        triggeringExamples: [
            Example("↓enum A {}\n"),
            Example("final ↓class B {}\n"),
            Example("internal struct C { ↓let d = 5 }\n"),
            Example("internal struct C { ↓static let d = 5 }\n"),
            Example("public struct C { ↓let d = 5 }\n"),
            Example("public struct C { ↓init() }\n"),
            Example("func a() {}\n"),
            Example("internal let a = 0\n↓func b() {}\n"),
            Example("""
            extension Foo {
                ↓func bar() {}
            }
            """)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension ExplicitACLRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [DeclSyntaxProtocol.Type] {
            [
                FunctionDeclSyntax.self,
                SubscriptDeclSyntax.self,
                VariableDeclSyntax.self,
                ProtocolDeclSyntax.self,
                InitializerDeclSyntax.self
            ]
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.classKeyword.positionAfterSkippingLeadingTrivia)
            }

            return node.modifiers.isPrivateOrFileprivate ? .skipChildren : .visitChildren
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.structKeyword.positionAfterSkippingLeadingTrivia)
            }

            return node.modifiers.isPrivateOrFileprivate ? .skipChildren : .visitChildren
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.enumKeyword.positionAfterSkippingLeadingTrivia)
            }

            return node.modifiers.isPrivateOrFileprivate ? .skipChildren : .visitChildren
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.actorKeyword.positionAfterSkippingLeadingTrivia)
            }

            return node.modifiers.isPrivateOrFileprivate ? .skipChildren : .visitChildren
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.protocolKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: TypealiasDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.typealiasKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                let position = node.modifiers.staticOrClassPosition ??
                               node.funcKeyword.positionAfterSkippingLeadingTrivia
                violations.append(position)
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                let position = node.modifiers.staticOrClassPosition ??
                               node.subscriptKeyword.positionAfterSkippingLeadingTrivia
                violations.append(position)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                violations.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if hasViolation(modifiers: node.modifiers) {
                let position = node.modifiers.staticOrClassPosition ??
                               node.letOrVarKeyword.positionAfterSkippingLeadingTrivia
                violations.append(position)
            }
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard let modifiers = node.modifiers,
                  modifiers.contains(where: \.isACLModifier) else {
                return .visitChildren
            }

            return .skipChildren
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        private func hasViolation(modifiers: ModifierListSyntax?) -> Bool {
            guard let modifiers = modifiers else {
                return true
            }

            return !modifiers.contains(where: \.isACLModifier)
        }
    }
}

private extension ModifierListSyntax? {
     var staticOrClassPosition: AbsolutePosition? {
         self?.first { modifier in
             modifier.name.tokenKind == .staticKeyword || modifier.name.tokenKind == .classKeyword
         }?.positionAfterSkippingLeadingTrivia
     }
 }
