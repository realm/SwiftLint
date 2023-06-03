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
            Example("public func a() {}"),
            // public, undocumented
            Example("// regular comment\npublic func a() {}"),
            // public, undocumented
            Example("/* regular comment */\npublic func a() {}"),
            // protocol member and inherited member are both undocumented
            Example("""
            /// docs
            public protocol A {
            // no docs
            var b: Int { get } }
            /// docs
            public struct C: A {

            public let b: Int
            }
            """),
            Example("""
            /// docs
            public class A {
                public init(argument: String) {}
            }
            """, configuration: ["excludes_trivial_init": true]),
        ]
    )
}

private extension MissingDocsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            } else {
                return .visitChildren
            }
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            if node.hasDocComment { return }

            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return
            }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.actorKeyword) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: AssociatedTypeDeclSyntax) {
            if node.hasDocComment { return }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.associatedtypeKeyword) {
                violations.append(violation)
            }
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            } else {
                return .visitChildren
            }
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            if node.hasDocComment { return }

            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return
            }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.classKeyword) {
                violations.append(violation)
            }
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visitPost(_ node: EnumCaseDeclSyntax) {
            if node.hasDocComment { return }

            guard let enumDecl = node.parentDeclGroup?.as(EnumDeclSyntax.self) else { return }

            let accessControlLevel = enumDecl.modifiers.accessibility ?? .internal
            violations.append(contentsOf: node.elements.compactMap {
                violation(for: accessControlLevel, at: $0.name)
            })
        }

        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            } else {
                return .visitChildren
            }
        }

        override func visitPost(_ node: EnumDeclSyntax) {
            if node.hasDocComment { return }

            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return
            }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.enumKeyword) {
                violations.append(violation)
            }
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            } else {
                return .visitChildren
            }
        }

        override func visitPost(_ node: ExtensionDeclSyntax) {
            if node.hasDocComment { return }

            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return
            }

            if configuration.excludesExtensions { return }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.extensionKeyword) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if node.hasDocComment { return }

            if node.modifiers.contains(keyword: .override) { return }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.funcKeyword) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if node.hasDocComment { return }

            if node.modifiers.contains(keyword: .override) { return }

            if node.signature.parameterClause.parameters.isEmpty, configuration.excludesTrivialInit {
                return
            }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.initKeyword) {
                violations.append(violation)
            }
        }

        override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            } else {
                return .visitChildren
            }
        }

        override func visitPost(_ node: ProtocolDeclSyntax) {
            if node.hasDocComment { return }

            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return
            }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.protocolKeyword) {
                violations.append(violation)
            }
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return .skipChildren
            } else {
                return .visitChildren
            }
        }

        override func visitPost(_ node: StructDeclSyntax) {
            if node.hasDocComment { return }

            if node.inheritanceClause != nil, configuration.excludesInheritedTypes {
                return
            }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.structKeyword) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if node.hasDocComment { return }

            if node.modifiers.contains(keyword: .override) { return }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.subscriptKeyword) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: TypeAliasDeclSyntax) {
            if node.hasDocComment { return }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.typealiasKeyword) {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            if node.hasDocComment { return }

            if node.modifiers.contains(keyword: .override) { return }

            if let violation = violation(
                for: node.modifiers.accessibility ?? node.defaultAccessibility,
                at: node.modifiers.staticOrClass ?? node.bindingSpecifier) {
                violations.append(violation)
            }
        }

        private func violation(
            for accessControlLevel: AccessControlLevel,
            at token: TokenSyntax
        ) -> ReasonedRuleViolation? {
            if let parameter = configuration.parameters.first(where: { $0.value == accessControlLevel }) {
                return ReasonedRuleViolation(
                    position: token.positionAfterSkippingLeadingTrivia,
                    reason: "\(accessControlLevel) declarations should be documented",
                    severity: parameter.severity
                )
            } else {
                return nil
            }
        }
    }
}

private extension DeclSyntaxProtocol {
    var hasDocComment: Bool {
        var pieces = leadingTrivia.pieces
        loop: while let piece = pieces.last {
            switch piece {
            case .newlines, .spaces, .tabs:
                pieces.removeLast()
            default:
                break loop
            }
        }
        switch pieces.last {
        case .docBlockComment, .docLineComment: return true
        default: return false
        }
    }
}

private extension SyntaxProtocol {
    var parentDeclGroup: (any DeclGroupSyntax)? {
        guard let parent else { return nil }
        if let declGroup = parent.asProtocol((any DeclGroupSyntax).self) {
            return declGroup
        } else {
            return parent.parentDeclGroup
        }
    }

    var defaultAccessibility: AccessControlLevel {
        if let declGroup = parentDeclGroup,
           declGroup.is(ExtensionDeclSyntax.self) || declGroup.is(ProtocolDeclSyntax.self) {
            return declGroup.modifiers.accessibility ?? .internal
        } else {
            return .internal
        }
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
