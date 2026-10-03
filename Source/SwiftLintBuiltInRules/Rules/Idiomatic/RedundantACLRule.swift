import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct RedundantACLRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "redundant_acl",
        name: "Redundant ACL",
        description: "Access level modifiers that only restate the default access level should be omitted",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "struct S {}",
            "public struct S {}",
            "private struct S {}",
            "open class C {}",
            "public struct S { internal let a = 1 }",
            "open class C { public func f() {} }",
            "struct S { private let a = 1 }",
            "private struct S { private let a = 1 }",
            "private struct S { internal let a = 1 }",
            "struct S { internal(set) var a = 1 }",
            "public struct S { public private(set) var a = 1 }",
            "extension E { public func f() {} }",
            "public extension E { internal func f() {} }",
            "private extension E { private func f() {} }",
            "public extension E { struct Bar { internal func baz() {} } }",
            "protocol P { func f() }",
            "struct S { func f() { let x = 1 } }",
            """
            public struct S {
                #if DEBUG
                internal let a = 1
                #endif
            }
            """,
        ]),
        triggeringExamples: #examples([
            "↓internal struct S {}",
            "↓internal protocol P {}",
            "↓internal extension E {}",
            "↓internal func f() {}",
            "↓internal let x = 1",
            "final ↓internal class C {}",
            "@objc ↓internal class C: NSObject {}",
            "↓internal struct S { ↓internal let a = 1 }",
            "struct S { ↓internal func f() {} }",
            "struct S { ↓internal init() {} }",
            "struct S { ↓internal struct T {} }",
            "struct S { static ↓internal let a = 1 }",
            "extension E { ↓internal func f() {} }",
            "public extension E { ↓public func f() {} }",
            "public extension E { ↓public struct Bar {} }",
            "package extension E { ↓package func f() {} }",
            "fileprivate extension E { ↓fileprivate func f() {} }",
            "private extension E { ↓fileprivate func f() {} }",
            "public struct S { struct T { ↓internal let x = 1 } }",
            """
            #if DEBUG
            ↓internal struct S {}
            #endif
            """,
        ]),
        corrections: #corrections([
            "↓internal struct S {}":
                "struct S {}",
            "final ↓internal class C {}":
                "final class C {}",
            """
            struct S {
                ↓internal let a = 1
            }
            """:
                """
                struct S {
                    let a = 1
                }
                """,
            """
            public extension E {
                ↓public func f() {}
            }
            """:
                """
                public extension E {
                    func f() {}
                }
                """,
            """
            /// Doc
            ↓internal struct S {
                ↓internal let a = 1
            }
            """:
                """
                /// Doc
                struct S {
                    let a = 1
                }
                """,
        ])
    )
}

private extension RedundantACLRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            if node.isRedundantAccessLevelModifier {
                violations.append(.init(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "'\(node.name.text)' is the default access level here and can be omitted"
                ))
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard node.isRedundantAccessLevelModifier else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return DeclModifierSyntax(leadingTrivia: node.leadingTrivia, name: .identifier(""))
        }
    }
}

private extension DeclModifierSyntax {
    var accessLevelKeyword: Keyword? {
        guard asAccessLevelModifier != nil, case let .keyword(keyword) = name.tokenKind else {
            return nil
        }
        return keyword
    }

    var isRedundantAccessLevelModifier: Bool {
        guard detail == nil, // `private(set)` etc. are covered by `redundant_set_access_control`.
              let keyword = accessLevelKeyword,
              let declaration = parent?.as(DeclModifierListSyntax.self)?.parent,
              let scope = declaration.declarationScope else {
            return false
        }
        switch keyword {
        case .private:
            // `private` at file scope means `fileprivate`, but inside a declaration it is narrower than that.
            return false
        case .fileprivate:
            return scope.defaultAccessLevel == .fileprivate || scope.defaultAccessLevel == .private
        case .internal:
            guard scope.defaultAccessLevel == .internal else {
                return false
            }
            // In a type more visible than `internal`, an explicit `internal` is an intentional restriction.
            if case let .member(typeDeclaration) = scope, !typeDeclaration.is(ExtensionDeclSyntax.self) {
                return typeDeclaration.effectiveAccessLevel == .internal
            }
            return true
        default:
            return keyword == scope.defaultAccessLevel
        }
    }
}

private enum DeclarationScope {
    case topLevel
    case member(Syntax)

    var defaultAccessLevel: Keyword {
        switch self {
        case .topLevel:
            return .internal
        case let .member(typeDeclaration):
            if let extensionDeclaration = typeDeclaration.as(ExtensionDeclSyntax.self) {
                return extensionDeclaration.modifiers.accessLevelModifier(setter: false)?.accessLevelKeyword
                    ?? .internal
            }
            return .internal
        }
    }
}

private extension Syntax {
    var declarationScope: DeclarationScope? {
        var current = parent
        while let node = current {
            if node.is(SourceFileSyntax.self) {
                return .topLevel
            }
            if node.is(CodeBlockSyntax.self) || node.is(ExprSyntax.self) || node.is(StmtSyntax.self) {
                return nil
            }
            if node.is(MemberBlockSyntax.self) {
                guard let typeDeclaration = node.parent, typeDeclaration.isTypeOrExtensionDeclaration else {
                    return nil
                }
                return .member(typeDeclaration)
            }
            current = node.parent
        }
        return nil
    }

    var effectiveAccessLevel: Keyword? {
        let explicitAccessLevel = asProtocol((any WithModifiersSyntax).self)?
            .modifiers.accessLevelModifier(setter: false)?.accessLevelKeyword
        return explicitAccessLevel ?? declarationScope?.defaultAccessLevel
    }

    var isTypeOrExtensionDeclaration: Bool {
        `is`(StructDeclSyntax.self)
            || `is`(ClassDeclSyntax.self)
            || `is`(ActorDeclSyntax.self)
            || `is`(EnumDeclSyntax.self)
            || `is`(ExtensionDeclSyntax.self)
    }
}
