import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct LowerACLThanParentRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "lower_acl_than_parent",
        name: "Lower ACL than Parent",
        description: "Ensure declarations have a lower access control level than their enclosing parent",
        kind: .lint,
        nonTriggeringExamples: [
            Example("public struct Foo { public func bar() {} }"),
            Example("internal struct Foo { func bar() {} }"),
            Example("struct Foo { func bar() {} }"),
            Example("struct Foo { internal func bar() {} }"),
            Example("open class Foo { public func bar() {} }"),
            Example("open class Foo { open func bar() {} }"),
            Example("fileprivate struct Foo { private func bar() {} }"),
            Example("private struct Foo { private func bar(id: String) }"),
            Example("extension Foo { public func bar() {} }"),
            Example("private struct Foo { fileprivate func bar() {} }"),
            Example("private func foo(id: String) {}"),
            Example("private class Foo { func bar() {} }"),
            Example("public extension Foo { struct Bar { public func baz() {} }}"),
            Example("public extension Foo { struct Bar { internal func baz() {} }}"),
            Example("internal extension Foo { struct Bar { internal func baz() {} }}"),
            Example("extension Foo { struct Bar { internal func baz() {} }}"),
        ],
        triggeringExamples: [
            Example("struct Foo { ↓public func bar() {} }"),
            Example("enum Foo { ↓public func bar() {} }"),
            Example("public class Foo { ↓open func bar() }"),
            Example("class Foo { ↓public private(set) var bar: String? }"),
            Example("private struct Foo { ↓public func bar() {} }"),
            Example("private class Foo { ↓public func bar() {} }"),
            Example("private actor Foo { ↓public func bar() {} }"),
            Example("fileprivate struct Foo { ↓public func bar() {} }"),
            Example("class Foo { ↓public func bar() {} }"),
            Example("actor Foo { ↓public func bar() {} }"),
            Example("private struct Foo { ↓internal func bar() {} }"),
            Example("fileprivate struct Foo { ↓internal func bar() {} }"),
            Example("extension Foo { struct Bar { ↓public func baz() {} }}"),
            Example("internal extension Foo { struct Bar { ↓public func baz() {} }}"),
            Example("private extension Foo { struct Bar { ↓public func baz() {} }}"),
            Example("fileprivate extension Foo { struct Bar { ↓public func baz() {} }}"),
            Example("private extension Foo { struct Bar { ↓internal func baz() {} }}"),
            Example("fileprivate extension Foo { struct Bar { ↓internal func baz() {} }}"),
            Example("public extension Foo { struct Bar { struct Baz { ↓public func qux() {} }}}"),
            Example("final class Foo { ↓public func bar() {} }"),
        ],
        corrections: [
            Example("struct Foo { ↓public func bar() {} }"):
                Example("struct Foo { func bar() {} }"),
            Example("enum Foo { ↓public func bar() {} }"):
                Example("enum Foo { func bar() {} }"),
            Example("public class Foo { ↓open func bar() }"):
                Example("public class Foo { public func bar() }"),
            Example("class Foo { ↓public private(set) var bar: String? }"):
                Example("class Foo { private(set) var bar: String? }"),
            Example("private struct Foo { ↓public func bar() {} }"):
                Example("private struct Foo { func bar() {} }"),
            Example("private class Foo { ↓public func bar() {} }"):
                Example("private class Foo { func bar() {} }"),
            Example("private actor Foo { ↓public func bar() {} }"):
                Example("private actor Foo { func bar() {} }"),
            Example("class Foo { ↓public func bar() {} }"):
                Example("class Foo { func bar() {} }"),
            Example("actor Foo { ↓public func bar() {} }"):
                Example("actor Foo { func bar() {} }"),
            Example("""
                struct Foo {
                    ↓public func bar() {}
                }
                """):
                Example("""
                struct Foo {
                    func bar() {}
                }
                """),
        ]
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

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
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
        self.is(StructDeclSyntax.self) ||
            self.is(ClassDeclSyntax.self) ||
            self.is(ActorDeclSyntax.self) ||
            self.is(EnumDeclSyntax.self)
    }

    var isExtensionDecl: Bool {
        self.is(ExtensionDeclSyntax.self)
    }

    var modifiers: DeclModifierListSyntax? {
        asProtocol((any WithModifiersSyntax).self)?.modifiers
    }
}
