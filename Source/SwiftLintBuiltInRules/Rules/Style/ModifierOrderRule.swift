import SourceKittenFramework
import SwiftLintCore
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

            let descriptions = node.modifierDescriptions
            let differences = descriptions
                .bubbleSort(by: configuration.preferredModifierOrder)
                .difference(from: descriptions)
            let orderedDescriptions = descriptions.applying(differences) ?? descriptions

            if let diff = zip(orderedDescriptions, descriptions).first(where: { $0.keyword != $1.keyword }) {
                violations.append(.init(
                    position: introducer.positionAfterSkippingLeadingTrivia,
                    reason: "\(diff.0.keyword) modifier should come before \(diff.1.keyword)"
                ))
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: DeclModifierListSyntax) -> DeclModifierListSyntax {
            let modifierDescriptions = node.modifierDescriptions
            let prevModifiers = modifierDescriptions.map(\.modifier)
            let differences = modifierDescriptions
                .bubbleSort(by: configuration.preferredModifierOrder)
                .map(\.modifier)
                .difference(from: prevModifiers)
            if differences.isEmpty {
                return super.visit(node)
            }
            numberOfCorrections += differences.count
            var newModifiers = prevModifiers
            for change in differences {
                switch change {
                case let .remove(offset, _, _):
                    newModifiers.remove(at: offset)
                case let .insert(offset, element, _):
                    let prevModifier = prevModifiers[offset]
                    newModifiers.insert(element.with(\.leadingTrivia, prevModifier.leadingTrivia), at: offset)
                    if offset == 0, newModifiers.count > 1 {
                        newModifiers[1] = newModifiers[1].with(\.leadingTrivia, [])
                    }
                }
            }
            let newNode = DeclModifierListSyntax(newModifiers)
                .with(\.leadingTrivia, node.leadingTrivia)
                .with(\.trailingTrivia, node.trailingTrivia)
            return super.visit(newNode)
        }
    }
}

private extension DeclModifierListSyntax {
    var modifierDescriptions: [ModifierDescription] {
        var descriptions: [ModifierDescription] = []

        for modifier in self {
            let keyword = modifier.name.text
            let position = modifier.positionAfterSkippingLeadingTrivia
            guard let group = SwiftDeclarationAttributeKind.ModifierGroup(modifierKeyword: keyword) else {
                continue
            }

            // Handle setter access modifiers like `private(set)``.
            if let detail = modifier.detail?.detail.tokenKind,
               case .identifier(let detailText) = detail, detailText == "set" {
                if case .acl = group {
                    descriptions.append(.init(
                        keyword: "\(keyword)(set)",
                        modifier: modifier,
                        group: .setterACL,
                        position: position
                    ))
                }
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
        case "nonisolated":
            self = .isolation
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
}

private struct ModifierDescription: Equatable {
    let keyword: String
    let modifier: DeclModifierSyntax
    let group: SwiftDeclarationAttributeKind.ModifierGroup
    let position: AbsolutePosition
}

private extension [ModifierDescription] {
    func bubbleSort(by preferredOrder: [SwiftDeclarationAttributeKind.ModifierGroup]) -> [ModifierDescription] {
        var sorted = Self()
        for element in self {
            var inserted = false
            for (index, sortedElement) in sorted.enumerated() {
                let elementIndex = preferredOrder.firstIndex(of: element.group)
                let sortedElementIndex = preferredOrder.firstIndex(of: sortedElement.group)
                if let elementIndex, let sortedElementIndex, elementIndex < sortedElementIndex {
                    sorted.insert(element, at: index)
                    inserted = true
                    break
                }
            }
            if !inserted {
                sorted.append(element)
            }
        }
        return sorted
    }
}
