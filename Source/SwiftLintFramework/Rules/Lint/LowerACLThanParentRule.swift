import SwiftSyntax

struct LowerACLThanParentRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            Example("extension Foo { struct Bar { internal func baz() {} }}")
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
            Example("final class Foo { ↓public func bar() {} }")
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
                Example("actor Foo { func bar() {} }")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension LowerACLThanParentRule {
    private final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: DeclModifierSyntax) {
            if node.isHigherACLThanParent {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
            guard
                node.isHigherACLThanParent,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let newNode: DeclModifierSyntax
            if node.name.tokenKind == .keyword(.open) {
                newNode = DeclModifierSyntax(
                    leadingTrivia: node.leadingTrivia ?? .zero,
                    name: .keyword(.public),
                    trailingTrivia: .space
                )
            } else {
                newNode = DeclModifierSyntax(name: .keyword(.internal, presence: .missing))
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
        case .keyword(.internal)
            where nearestNominalParent.modifiers.isPrivate ||
                nearestNominalParent.modifiers.isFileprivate:
            return true
        case .keyword(.internal)
            where !nearestNominalParent.modifiers.containsACLModifier:
            guard let nominalExtension = nearestNominalParent.nearestNominalExtensionDeclParent() else {
                return false
            }
            return nominalExtension.modifiers.isPrivate ||
                nominalExtension.modifiers.isFileprivate
        case .keyword(.public)
            where nearestNominalParent.modifiers.isPrivate ||
                nearestNominalParent.modifiers.isFileprivate ||
                nearestNominalParent.modifiers.isInternal:
            return true
        case .keyword(.public)
            where !nearestNominalParent.modifiers.containsACLModifier:
            guard let nominalExtension = nearestNominalParent.nearestNominalExtensionDeclParent() else {
                return true
            }
            return !nominalExtension.modifiers.isPublic
        case .keyword(.open) where !nearestNominalParent.modifiers.isOpen:
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

    var modifiers: ModifierListSyntax? {
        if let node = self.as(StructDeclSyntax.self) {
            return node.modifiers
        } else if let node = self.as(ClassDeclSyntax.self) {
            return node.modifiers
        } else if let node = self.as(ActorDeclSyntax.self) {
            return node.modifiers
        } else if let node = self.as(EnumDeclSyntax.self) {
            return node.modifiers
        } else if let node = self.as(ExtensionDeclSyntax.self) {
            return node.modifiers
        } else {
            return nil
        }
    }
}

private extension ModifierListSyntax? {
    var isPrivate: Bool {
        self?.contains(where: { $0.name.tokenKind == .keyword(.private) }) == true
    }

    var isInternal: Bool {
        self?.contains(where: { $0.name.tokenKind == .keyword(.internal) }) == true
    }

    var isPublic: Bool {
        self?.contains(where: { $0.name.tokenKind == .keyword(.public) }) == true
    }

    var isOpen: Bool {
        self?.contains(where: { $0.name.tokenKind == .keyword(.open) }) == true
    }

    var containsACLModifier: Bool {
        guard self?.isEmpty == false else {
            return false
        }
        let aclTokens: Set<TokenKind> = [
            .keyword(.private),
            .keyword(.fileprivate),
            .keyword(.internal),
            .keyword(.public),
            .keyword(.open)
        ]

        return self?.contains(where: {
            aclTokens.contains($0.name.tokenKind)
        }) == true
    }
}
