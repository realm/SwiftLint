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
@SwiftSyntaxRule
struct PrivateSwiftUIStatePropertyRule: SwiftSyntaxCorrectableRule, OptInRule {
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

        /// LIFO stack that stores type inheritance clauses for each visited node
        /// The last value is the inheritance clause for the most recently visited node
        /// A nil value indicates that the node does not provide any inheritance clause
        private var visitedTypeInheritances = Stack<InheritanceClauseSyntax?>()

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            visitedTypeInheritances.push(node.inheritanceClause)
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            visitedTypeInheritances.pop()
        }

        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            visitedTypeInheritances.push(node.inheritanceClause)
            return .visitChildren
        }

        override func visitPost(_ node: StructDeclSyntax) {
            visitedTypeInheritances.pop()
        }

        override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
            visitedTypeInheritances.push(node.inheritanceClause)
            return .visitChildren
        }

        override func visitPost(_ node: ActorDeclSyntax) {
            visitedTypeInheritances.pop()
        }

        override func visitPost(_ node: MemberBlockItemSyntax) {
            guard
                let decl = node.decl.as(VariableDeclSyntax.self),
                let inheritanceClause = visitedTypeInheritances.peek() as? InheritanceClauseSyntax,
                inheritanceClause.conformsToApplicableSwiftUIProtocol,
                decl.attributes.hasStateAttribute
            else {
                return
            }

            guard let accessLevelModifier = decl.modifiers.accessLevelModifier else {
                violations.append(decl.bindingSpecifier.positionAfterSkippingLeadingTrivia)
                violationCorrections.append(
                    ViolationCorrection(
                        start: decl.bindingSpecifier.positionAfterSkippingLeadingTrivia,
                        end: decl.bindingSpecifier.positionAfterSkippingLeadingTrivia,
                        replacement: "\(TokenSyntax.keyword(.private).text) "
                    )
                )
                return
            }

            guard !accessLevelModifier.isPrivate else { return }

            violations.append(accessLevelModifier.positionAfterSkippingLeadingTrivia)
            violationCorrections.append(
                ViolationCorrection(
                    start: accessLevelModifier.positionAfterSkippingLeadingTrivia,
                    end: accessLevelModifier.endPositionBeforeTrailingTrivia,
                    replacement: TokenSyntax.keyword(.private).text
                )
            )
        }
    }
}

private extension InheritanceClauseSyntax {
    static let applicableSwiftUIProtocols: Set<String> = ["View", "App", "Scene"]

    var conformsToApplicableSwiftUIProtocol: Bool {
        inheritedTypes.containsInheritedType(inheritedTypes: Self.applicableSwiftUIProtocols)
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

private extension DeclModifierSyntax {
    // Returns true if the access level modifier is anything other than private
    // Private getters and setters are not considered private for the scope of this rule
    var isPrivate: Bool {
        name.tokenKind == .keyword(.private) && detail == nil
    }
}
