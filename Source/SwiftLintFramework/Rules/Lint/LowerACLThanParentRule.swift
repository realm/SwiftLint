import SwiftSyntax

struct LowerACLThanParentRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "lower_acl_than_parent",
        name: "Lower ACL than parent",
        description: "Ensure declarations have a lower access control level than their enclosing parent",
        kind: .lint,
        nonTriggeringExamples: [
            Example("public struct Foo { public func bar() {} }"),
            Example("internal struct Foo { func bar() {} }"),
            Example("struct Foo { func bar() {} }"),
            Example("open class Foo { public func bar() {} }"),
            Example("open class Foo { open func bar() {} }"),
            Example("fileprivate struct Foo { private func bar() {} }"),
            Example("private struct Foo { private func bar(id: String) }"),
            Example("extension Foo { public func bar() {} }"),
            Example("private struct Foo { fileprivate func bar() {} }"),
            Example("private func foo(id: String) {}"),
            Example("private class Foo { func bar() {} }")
        ],
        triggeringExamples: [
            Example("struct Foo { ↓public func bar() {} }"),
            Example("enum Foo { ↓public func bar() {} }"),
            Example("public class Foo { ↓open func bar() }"),
            Example("class Foo { ↓public private(set) var bar: String? }"),
            Example("private struct Foo { ↓public func bar() {} }"),
            Example("private class Foo { ↓public func bar() {} }"),
            Example("private actor Foo { ↓public func bar() {} }"),
            Example("class Foo { ↓public func bar() {} }"),
            Example("actor Foo { ↓public func bar() {} }")
        ],
        corrections: [
            Example("struct Foo { ↓public func bar() {} }"):
                Example("struct Foo { func bar() {} }"),
            Example("enum Foo { ↓public func bar() {} }"):
                Example("enum Foo { func bar() {} }"),
            Example("public class Foo { ↓open func bar() }"):
                Example("public class Foo { func bar() }"),
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
            let newNode = node.withName(
                .contextualKeyword("", leadingTrivia: node.leadingTrivia ?? .zero)
            )
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
        case .internalKeyword
            where nearestNominalParent.modifiers.isPrivate ||
                nearestNominalParent.modifiers.isFileprivate:
            return true
        case .publicKeyword
            where nearestNominalParent.modifiers.isPrivate || nearestNominalParent.modifiers.isInternal:
            return true
        case .contextualKeyword("open") where !nearestNominalParent.modifiers.isOpen:
            return true
        default:
            return false
        }
    }
}

private extension SyntaxProtocol {
    func nearestNominalParent() -> Syntax? {
        guard let parent = parent else {
            return nil
        }

        return parent.isNominalTypeDecl ? parent : parent.nearestNominalParent()
    }
}

private extension Syntax {
    var isNominalTypeDecl: Bool {
        self.is(StructDeclSyntax.self) ||
            self.is(ClassDeclSyntax.self) ||
            self.is(ActorDeclSyntax.self) ||
            self.is(EnumDeclSyntax.self)
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
        } else {
            return nil
        }
    }
}

private extension ModifierListSyntax? {
    var isFileprivate: Bool {
        self?.contains(where: { $0.name.tokenKind == .fileprivateKeyword }) == true
    }

    var isPrivate: Bool {
        self?.contains(where: { $0.name.tokenKind == .privateKeyword }) == true
    }

    var isInternal: Bool {
        self?.allSatisfy { modifier in
            switch modifier.name.tokenKind {
            case .fileprivateKeyword, .privateKeyword, .publicKeyword, .contextualKeyword("open"):
                return false
            default:
                return true
            }
        } != false
    }

    var isOpen: Bool {
        self?.contains(where: { $0.name.tokenKind == .contextualKeyword("open") }) == true
    }
}
