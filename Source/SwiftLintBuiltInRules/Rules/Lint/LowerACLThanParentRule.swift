import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct LowerACLThanParentRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "lower_acl_than_parent",
        name: "Lower ACL than Parent",
        description: "Ensure declarations have a lower access control level than their enclosing parent",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "public struct Foo { public func bar() {} }",
            "internal struct Foo { func bar() {} }",
            "struct Foo { func bar() {} }",
            "struct Foo { internal func bar() {} }",
            "open class Foo { public func bar() {} }",
            "open class Foo { open func bar() {} }",
            "fileprivate struct Foo { private func bar() {} }",
            "private struct Foo { private func bar(id: String) }",
            "extension Foo { public func bar() {} }",
            "private struct Foo { fileprivate func bar() {} }",
            "private func foo(id: String) {}",
            "private class Foo { func bar() {} }",
            "public extension Foo { struct Bar { public func baz() {} }}",
            "public extension Foo { struct Bar { internal func baz() {} }}",
            "internal extension Foo { struct Bar { internal func baz() {} }}",
            "extension Foo { struct Bar { internal func baz() {} }}",
        ]),
        triggeringExamples: #examples([
            "struct Foo { ↓public func bar() {} }",
            "enum Foo { ↓public func bar() {} }",
            "public class Foo { ↓open func bar() }",
            "class Foo { ↓public private(set) var bar: String? }",
            "private struct Foo { ↓public func bar() {} }",
            "private class Foo { ↓public func bar() {} }",
            "private actor Foo { ↓public func bar() {} }",
            "fileprivate struct Foo { ↓public func bar() {} }",
            "class Foo { ↓public func bar() {} }",
            "actor Foo { ↓public func bar() {} }",
            "private struct Foo { ↓internal func bar() {} }",
            "fileprivate struct Foo { ↓internal func bar() {} }",
            "extension Foo { struct Bar { ↓public func baz() {} }}",
            "internal extension Foo { struct Bar { ↓public func baz() {} }}",
            "private extension Foo { struct Bar { ↓public func baz() {} }}",
            "fileprivate extension Foo { struct Bar { ↓public func baz() {} }}",
            "private extension Foo { struct Bar { ↓internal func baz() {} }}",
            "fileprivate extension Foo { struct Bar { ↓internal func baz() {} }}",
            "public extension Foo { struct Bar { struct Baz { ↓public func qux() {} }}}",
            "final class Foo { ↓public func bar() {} }",
        ]),
        corrections: #corrections([
            "struct Foo { ↓public func bar() {} }":
                "struct Foo { func bar() {} }",
            "enum Foo { ↓public func bar() {} }":
                "enum Foo { func bar() {} }",
            "public class Foo { ↓open func bar() }":
                "public class Foo { public func bar() }",
            "class Foo { ↓public private(set) var bar: String? }":
                "class Foo { private(set) var bar: String? }",
            "private struct Foo { ↓public func bar() {} }":
                "private struct Foo { func bar() {} }",
            "private class Foo { ↓public func bar() {} }":
                "private class Foo { func bar() {} }",
            "private actor Foo { ↓public func bar() {} }":
                "private actor Foo { func bar() {} }",
            "class Foo { ↓public func bar() {} }":
                "class Foo { func bar() {} }",
            "actor Foo { ↓public func bar() {} }":
                "actor Foo { func bar() {} }",
            """
                struct Foo {
                    ↓public func bar() {}
                }
                """:
                """
                struct Foo {
                    func bar() {}
                }
                """,
        ])
    )
}

private extension LowerACLThanParentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierSyntax) {
            if node.isHigherACLThanParent {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard node.isHigherACLThanParent else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            let newNode: DeclModifierSyntax
            if node.name.tokenKind == .keyword(.open) {
                newNode = DeclModifierSyntax(
                    leadingTrivia: node.leadingTrivia,
                    name: .keyword(.public),
                    trailingTrivia: .space
                )
            } else {
                newNode = DeclModifierSyntax(
                    leadingTrivia: node.leadingTrivia,
                    name: .identifier("")
                )
            }

            return super.visit(newNode)
        }
    }
}

private extension DeclModifierSyntax {
    var isHigherACLThanParent: Bool {
        guard let nearestNominalParent = parent?.nearestNominalParent() else {
            return false
        }

        switch name.tokenKind {
        case .keyword(.internal) where nearestNominalParent.modifiers?.containsPrivateOrFileprivate() == true:
            return true
        case .keyword(.internal) where nearestNominalParent.modifiers?.accessLevelModifier == nil:
            guard let nominalExtension = nearestNominalParent.nearestNominalExtensionDeclParent() else {
                return false
            }
            return nominalExtension.modifiers?.containsPrivateOrFileprivate() == true
        case .keyword(.public) where nearestNominalParent.modifiers?.containsPrivateOrFileprivate() == true ||
                                     nearestNominalParent.modifiers?.contains(keyword: .internal) == true:
            return true
        case .keyword(.public) where nearestNominalParent.modifiers?.accessLevelModifier == nil:
            guard let nominalExtension = nearestNominalParent.nearestNominalExtensionDeclParent() else {
                return true
            }
            return nominalExtension.modifiers?.contains(keyword: .public) == false
        case .keyword(.open) where nearestNominalParent.modifiers?.contains(keyword: .open) == false:
            return true
        default:
            return false
        }
    }
}

private extension SyntaxProtocol {
    func nearestNominalParent() -> Syntax? {
        guard let parent else {
            return nil
        }

        return parent.isNominalTypeDecl ? parent : parent.nearestNominalParent()
    }

    func nearestNominalExtensionDeclParent() -> Syntax? {
        guard let parent, !parent.isNominalTypeDecl else {
            return nil
        }

        return parent.isExtensionDecl ? parent : parent.nearestNominalExtensionDeclParent()
    }
}

private extension Syntax {
    var isNominalTypeDecl: Bool {
        `is`(StructDeclSyntax.self) ||
            `is`(ClassDeclSyntax.self) ||
            `is`(ActorDeclSyntax.self) ||
            `is`(EnumDeclSyntax.self)
    }

    var isExtensionDecl: Bool {
        `is`(ExtensionDeclSyntax.self)
    }

    var modifiers: DeclModifierListSyntax? {
        asProtocol((any WithModifiersSyntax).self)?.modifiers
    }
}
