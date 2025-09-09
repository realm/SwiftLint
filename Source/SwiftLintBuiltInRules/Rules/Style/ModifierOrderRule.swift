import SourceKittenFramework
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct ModifierOrderRule: Rule {
    var configuration = ModifierOrderConfiguration()

    static let description = RuleDescription(
        identifier: "modifier_order",
        name: "Modifier Order",
        description: "Modifier order should be consistent.",
        kind: .style,
        nonTriggeringExamples: ModifierOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ModifierOrderRuleExamples.triggeringExamples
    )
}

private extension ModifierOrderRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclModifierListSyntax) {
            guard let parent = node.parent else {
                return
            }

            let introducer: TokenSyntax? = parent.asProtocol((any DeclGroupSyntax).self)?.introducer
                ?? parent.as(FunctionDeclSyntax.self)?.funcKeyword
                ?? parent.as(InitializerDeclSyntax.self)?.initKeyword
                ?? parent.as(SubscriptDeclSyntax.self)?.subscriptKeyword
                ?? parent.as(VariableDeclSyntax.self)?.bindingSpecifier

            guard let introducer else {
                return
            }

            let violatingModifiers = violatingModifiers(
                node.modifierDescriptions,
                preferredModifierOrder: configuration.preferredModifierOrder
            )
            if let (preferredModifier, declaredModifier) = violatingModifiers.first {
                violations.append(.init(
                    position: introducer.positionAfterSkippingLeadingTrivia,
                    reason: "\(preferredModifier.keyword) modifier should come before \(declaredModifier.keyword)"
                ))
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierListSyntax) -> DeclModifierListSyntax {
            let orderedModifiers = node.modifierDescriptions
                .sorted { first, second in
                    let firstIndex = configuration.preferredModifierOrder.firstIndex(of: first.group)
                    let secondIndex = configuration.preferredModifierOrder.firstIndex(of: second.group)
                    if let firstIndex, let secondIndex {
                        return firstIndex < secondIndex
                    }
                    return true
                }
                .map { $0.modifier.with(\.leadingTrivia, []).with(\.trailingTrivia, .space) }
            let newNode = DeclModifierListSyntax(orderedModifiers)
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
            return super.visit(newNode)
        }
    }
}

private func violatableModifiers(
    _ declaredModifiers: [ModifierDescription],
    preferredModifierOrder: [SwiftDeclarationAttributeKind.ModifierGroup]
) -> [ModifierDescription] {
    let preferredModifierGroups = [.atPrefixed] + preferredModifierOrder
    return declaredModifiers.filter { preferredModifierGroups.contains($0.group) }
}

private func prioritizedModifiers(
    violatableModifiers: [ModifierDescription],
    preferredModifierOrder: [SwiftDeclarationAttributeKind.ModifierGroup]
) -> [(priority: Int, modifier: ModifierDescription)] {
    let prioritizedPreferredModifierGroups = ([.atPrefixed] + preferredModifierOrder).enumerated()
    return violatableModifiers.reduce(
        into: [(priority: Int, modifier: ModifierDescription)]()
    ) { prioritizedModifiers, modifier in
        guard let priority = prioritizedPreferredModifierGroups.first(
            where: { _, group in modifier.group == group }
        )?.offset else {
            return
        }
        prioritizedModifiers.append((priority: priority, modifier: modifier))
    }
}

private func violatingModifiers(
    _ declaredModifiers: [ModifierDescription],
    preferredModifierOrder: [SwiftDeclarationAttributeKind.ModifierGroup]
) -> [(preferredModifier: ModifierDescription, declaredModifier: ModifierDescription)] {
    let violatableModifiers = violatableModifiers(declaredModifiers, preferredModifierOrder: preferredModifierOrder)
    let prioritizedModifiers = prioritizedModifiers(violatableModifiers: violatableModifiers, preferredModifierOrder: preferredModifierOrder)
    let sortedByPriorityModifiers = prioritizedModifiers
        .sorted { $0.priority < $1.priority }
        .map(\.modifier)

    return zip(sortedByPriorityModifiers, violatableModifiers).filter { $0 != $1 }
}

private extension DeclModifierListSyntax {
    var modifierDescriptions: [ModifierDescription] {
        var descriptions: [ModifierDescription] = []

        for modifier in self {
            let keyword = modifier.name.text
            let position = modifier.positionAfterSkippingLeadingTrivia

            // Handle setter access modifiers like `private(set)``.
            if let detail = modifier.detail?.detail.tokenKind,
               case .identifier(let detailText) = detail,
               detailText == "set" {
                guard let group = SwiftDeclarationAttributeKind.ModifierGroup(setterModifierKeyword: keyword) else {
                    continue
                }
                descriptions.append(.init(
                    keyword: "\(keyword)(set)",
                    modifier: modifier,
                    group: group,
                    position: position
                ))
                continue
            }

            // Handle regular modifiers.
            guard let group = SwiftDeclarationAttributeKind.ModifierGroup(modifierKeyword: keyword) else {
                continue
            }

            descriptions.append(.init(
                keyword: keyword,
                modifier: modifier,
                group: group,
                position: position
            ))
        }

        return descriptions
    }
}

private extension SwiftDeclarationAttributeKind.ModifierGroup {
    init?(modifierKeyword: String) { // swiftlint:disable:this cyclomatic_complexity
        switch modifierKeyword {
        case "override":
            self = .override
        case "weak":
            self = .owned
        case "final":
            self = .final
        case "required":
            self = .required
        case "convenience":
            self = .convenience
        case "lazy":
            self = .lazy
        case "dynamic":
            self = .dynamic
        case "private", "fileprivate", "internal", "public", "open":
            self = .acl
        case "mutating", "nonmutating":
            self = .mutators
        case "static", "class":
            self = .typeMethods
        case _ where modifierKeyword.hasPrefix("@"):
            self = .atPrefixed
        default:
            return nil
        }
    }

    init?(setterModifierKeyword: String) {
        if ["private", "fileprivate", "internal", "public", "open"].contains(setterModifierKeyword) {
            self = .setterACL
        } else {
            return nil
        }
    }
}

private struct ModifierDescription: Equatable {
    let keyword: String
    let modifier: DeclModifierSyntax
    let group: SwiftDeclarationAttributeKind.ModifierGroup
    let position: AbsolutePosition
}
