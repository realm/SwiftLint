import SourceKittenFramework

public struct ModifierOrderRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = ModifierOrderConfiguration(
        preferredModifierOrder: [
            .override,
            .acl,
            .setterACL,
            .dynamic,
            .mutators,
            .lazy,
            .final,
            .required,
            .convenience,
            .typeMethods,
            .owned
        ]
    )

    public init() {}

    public static let description = RuleDescription(
        identifier: "modifier_order",
        name: "Modifier Order",
        description: "Modifier order should be consistent.",
        kind: .style,
        minSwiftVersion: .fourDotOne ,
        nonTriggeringExamples: ModifierOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ModifierOrderRuleExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let offset = dictionary.offset else {
            return []
        }

        let violatableModifiers = self.violatableModifiers(declaredModifiers: dictionary.modifierDescriptions)
        let prioritizedModifiers = self.prioritizedModifiers(violatableModifiers: violatableModifiers)
        let sortedByPriorityModifiers = prioritizedModifiers.sorted(
            by: { lhs, rhs in lhs.priority < rhs.priority }
        ).map { $0.modifier }

        let violatingModifiers = zip(
            sortedByPriorityModifiers,
            violatableModifiers
        ).filter { sortedModifier, unsortedModifier in
            return sortedModifier != unsortedModifier
        }

        if let first = violatingModifiers.first {
            let preferredModifier = first.0
            let declaredModifier = first.1
            let reason = "\(preferredModifier.keyword) modifier should be before \(declaredModifier.keyword)."
            return [
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: reason
                )
            ]
        } else {
            return []
        }
    }

    private func violatableModifiers(declaredModifiers: [ModifierDescription]) -> [ModifierDescription] {
        let preferredModifierGroups = ([.atPrefixed] + configuration.preferredModifierOrder)
        return declaredModifiers.filter { preferredModifierGroups.contains($0.group) }
    }

    private func prioritizedModifiers(
        violatableModifiers: [ModifierDescription]
    ) -> [(priority: Int, modifier: ModifierDescription)] {
        let prioritizedPreferredModifierGroups = ([.atPrefixed] + configuration.preferredModifierOrder).enumerated()
        return violatableModifiers.reduce(
            [(priority: Int, modifier: ModifierDescription)]()
        ) { prioritizedModifiers, modifier in
            guard let priority = prioritizedPreferredModifierGroups.first(
                where: { _, group in modifier.group == group }
            )?.offset else {
                return prioritizedModifiers
            }
            return prioritizedModifiers + [(priority: priority, modifier: modifier)]
        }
    }
}

private extension Dictionary where Key == String, Value == SourceKitRepresentable {
    var modifierDescriptions: [ModifierDescription] {
        let staticKinds = [SwiftDeclarationKind.functionMethodClass, .functionMethodStatic, .varClass, .varStatic]
        let staticKindsAndOffsets = kindsAndOffsets(in: staticKinds).map { [$0] } ?? []
        return (swiftAttributes + staticKindsAndOffsets)
            .sorted {
                guard let rhsOffset = $0.offset, let lhsOffset = $1.offset else {
                    return false
                }
                return rhsOffset < lhsOffset
            }
            .compactMap {
                if let attribute = $0.attribute,
                   let modifierGroup = SwiftDeclarationAttributeKind.ModifierGroup(rawAttribute: attribute) {
                    return ModifierDescription(
                        keyword: attribute.lastComponentAfter("."),
                        group: modifierGroup
                    )
                } else if let kind = $0.kind {
                    return ModifierDescription(
                        keyword: kind.lastComponentAfter("."),
                        group: .typeMethods
                    )
                }
                return nil
            }
    }

    private func kindsAndOffsets(in declarationKinds: [SwiftDeclarationKind]) -> [String: SourceKitRepresentable]? {
        guard let kind = kind, let offset = offset,
            let declarationKind = SwiftDeclarationKind(rawValue: kind),
            declarationKinds.contains(declarationKind) else {
                return nil
        }

        return ["key.kind": kind, "key.offset": Int64(offset)]
    }
}

private extension String {
    func lastComponentAfter(_ charachter: String) -> String {
        return components(separatedBy: charachter).last ?? ""
    }
}

private struct ModifierDescription: Equatable {
    let keyword: String
    let group: SwiftDeclarationAttributeKind.ModifierGroup
}
