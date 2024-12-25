import SwiftSyntax

/// Require that any state properties in SwiftUI be declared as private
///
/// State and StateObject properties should only be accessible
/// from inside a SwiftUI App, View, or Scene, or from methods called by it.
///
/// Per Apple's documentation on [State](https://developer.apple.com/documentation/swiftui/state)
/// and [StateObject](https://developer.apple.com/documentation/swiftui/stateobject)
///
/// Declare state and state objects as private to prevent setting them from a memberwise initializer,
/// which can conflict with the storage management that SwiftUI provides:
@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct PrivateSwiftUIStatePropertyRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "private_swiftui_state",
        name: "Private SwiftUI State Properties",
        description: "SwiftUI state properties should be private",
        kind: .lint,
        nonTriggeringExamples: PrivateSwiftUIStatePropertyRuleExamples.nonTriggeringExamples,
        triggeringExamples: PrivateSwiftUIStatePropertyRuleExamples.triggeringExamples,
        corrections: PrivateSwiftUIStatePropertyRuleExamples.corrections
    )
}

private extension PrivateSwiftUIStatePropertyRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
            [ProtocolDeclSyntax.self]
        }

        /// LIFO stack that stores if a type conforms to SwiftUI protocols.
        /// `true` indicates that SwiftUI state properties should be
        /// checked in the scope of the last entered declaration.
        private var swiftUITypeScopes = Stack<Bool>()

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            swiftUITypeScopes.push(node.inheritanceClause.conformsToApplicableSwiftUIProtocol)
            return .visitChildren
        }

        override func visitPost(_: ClassDeclSyntax) {
            swiftUITypeScopes.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            swiftUITypeScopes.push(node.inheritanceClause.conformsToApplicableSwiftUIProtocol)
            return .visitChildren
        }

        override func visitPost(_: StructDeclSyntax) {
            swiftUITypeScopes.pop()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            swiftUITypeScopes.push(node.inheritanceClause.conformsToApplicableSwiftUIProtocol)
            return .visitChildren
        }

        override func visitPost(_: ActorDeclSyntax) {
            swiftUITypeScopes.pop()
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard node.parent?.is(MemberBlockItemSyntax.self) == true,
                swiftUITypeScopes.peek() ?? false,
                node.containsSwiftUIStateAccessLevelViolation
            else {
                return
            }

            if let firstAccessLevelModifier = node.modifiers.accessLevelModifier {
                violations.append(firstAccessLevelModifier.positionAfterSkippingLeadingTrivia)
            } else {
                violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        /// LIFO stack that stores if a type conforms to SwiftUI protocols.
        /// `true` indicates that SwiftUI state properties should be
        /// checked in the scope of the last entered declaration.
        private var swiftUITypeScopes = Stack<Bool>()

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            swiftUITypeScopes.push(node.inheritanceClause.conformsToApplicableSwiftUIProtocol)
            return super.visit(node)
        }

        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            swiftUITypeScopes.push(node.inheritanceClause.conformsToApplicableSwiftUIProtocol)
            return super.visit(node)
        }

        override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
            swiftUITypeScopes.push(node.inheritanceClause.conformsToApplicableSwiftUIProtocol)
            return super.visit(node)
        }

        override func visitPost(_ node: Syntax) {
            if node.is(ClassDeclSyntax.self) ||
               node.is(StructDeclSyntax.self) ||
               node.is(ActorDeclSyntax.self) {
                swiftUITypeScopes.pop()
            }
        }

        override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
            guard
                node.parent?.is(MemberBlockItemSyntax.self) == true,
                swiftUITypeScopes.peek() ?? false,
                node.containsSwiftUIStateAccessLevelViolation
            else {
                return DeclSyntax(node)
            }

            correctionPositions.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)

            // If there are no modifiers present on the current syntax node,
            // then we should retain the binding specifier's leading trivia
            // by appending it to our inserted private access level modifier
            if node.modifiers.isEmpty {
                // Extract the leading trivia from the binding specifier and apply it to the private modifier
                let privateModifier = DeclModifierSyntax(
                    leadingTrivia: node.bindingSpecifier.leadingTrivia,
                    name: .keyword(.private),
                    trailingTrivia: .space
                )

                let bindingSpecifier = node.bindingSpecifier.with(\.leadingTrivia, [])
                let newNode = node
                    .with(\.modifiers, [privateModifier])
                    .with(\.bindingSpecifier, bindingSpecifier)
                return DeclSyntax(newNode)
            }

            // If any existing, violating access modifiers are present
            // then we should extract their trivia and
            // append it to the inserted private access level modifier
            let existingAccessLevelModifiers = node.modifiers.filter { $0.asAccessLevelModifier != nil }
            // Remove any existing access control modifiers, but preserve any of their leading and trailing trivia
            // Existing trivia will be appended to the rewritten access modifier
            let previousAccessModifierLeadingTrivia = existingAccessLevelModifiers
                .map(\.leadingTrivia)
                .reduce(Trivia(pieces: [])) { partialResult, trivia in
                    partialResult.merging(trivia)
                }

            let previousAccessModifierTrailingTrivia = existingAccessLevelModifiers
                .map(\.trailingTrivia)
                .reduce(Trivia(pieces: [])) { partialResult, trivia in
                    partialResult.merging(trivia)
                }

            let filteredModifiers = node.modifiers.filter { $0.asAccessLevelModifier == nil }
            // Extract the leading trivia from the binding specifier and apply it to the private modifier
            let privateModifier = DeclModifierSyntax(
                leadingTrivia: previousAccessModifierLeadingTrivia,
                name: .keyword(.private),
                trailingTrivia: previousAccessModifierTrailingTrivia.merging(.space)
            )

            return DeclSyntax(
                node.with(\.modifiers, [privateModifier] + filteredModifiers)
            )
        }
    }
}

private extension VariableDeclSyntax {
    var containsSwiftUIStateAccessLevelViolation: Bool {
        attributes.hasStateAttribute && !modifiers.containsPrivateOrFileprivate()
    }
}

private extension InheritanceClauseSyntax? {
    static let applicableSwiftUIProtocols: Set<String> = ["View", "App", "Scene"]

    var conformsToApplicableSwiftUIProtocol: Bool {
        self?.inheritedTypes.containsInheritedType(inheritedTypes: Self.applicableSwiftUIProtocols) ?? false
    }
}

private extension InheritedTypeListSyntax {
    func containsInheritedType(inheritedTypes: Set<String>) -> Bool {
        contains {
            guard let simpleType = $0.type.as(IdentifierTypeSyntax.self) else { return false }

            return inheritedTypes.contains(simpleType.name.text)
        }
    }
}

private extension AttributeListSyntax {
    /// Returns `true` if the attribute's identifier is equal to `State` or `StateObject`
    var hasStateAttribute: Bool {
        contains { attr in
            guard let stateAttr = attr.as(AttributeSyntax.self),
                  let identifier = stateAttr.attributeName.as(IdentifierTypeSyntax.self) else {
                return false
            }

            return identifier.name.text == "State" || identifier.name.text == "StateObject"
        }
    }
}
