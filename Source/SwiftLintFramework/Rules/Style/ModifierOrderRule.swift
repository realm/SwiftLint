import Foundation
import SourceKittenFramework

public struct ModifierOrderRule: ASTRule, OptInRule, ConfigurationProviderRule, CorrectableRule {
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

        let violatingModifiers = self.violatingModifiers(dictionary: dictionary)

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

    public func correct(file: File) -> [Correction] {
        return correct(file: file, dictionary: file.structure.dictionary)
    }

    private func correct(file: File, dictionary: [String: SourceKitRepresentable]) -> [Correction] {
        return dictionary.substructure.flatMap { subDict -> [Correction] in
            var corrections = correct(file: file, dictionary: subDict)

            if let kindString = subDict.kind,
                let kind = KindType(rawValue: kindString) {
                corrections += correct(file: file, kind: kind, dictionary: subDict)
            }

            return corrections
        }
    }

    private func correct(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [Correction] {
        guard let offset = dictionary.offset else { return [] }
        let originalContents = file.contents.bridge()
        let violatingRanges = violatingModifiers(dictionary: dictionary)
            .compactMap { preferred, declared -> (NSRange, NSRange)? in
                guard
                    let preferredRange = originalContents.byteRangeToNSRange(
                        start: preferred.offset,
                        length: preferred.length
                    ).flatMap({ file.ruleEnabled(violatingRange: $0, for: self) }),
                    let declaredRange = originalContents.byteRangeToNSRange(
                        start: declared.offset,
                        length: declared.length
                    ).flatMap({ file.ruleEnabled(violatingRange: $0, for: self) }) else {
                    return nil
                }
                return (preferredRange, declaredRange)
            }

        let corrections: [Correction]
        if violatingRanges.isEmpty {
            corrections = []
        } else {
            var correctedContents = originalContents

            violatingRanges.reversed().forEach { preferredModifierRange, declaredModifierRange in
                correctedContents = correctedContents.replacingCharacters(
                    in: declaredModifierRange,
                    with: originalContents.substring(with: preferredModifierRange)
                ).bridge()
            }

            file.write(correctedContents.bridge())

            corrections = [
                Correction(
                    ruleDescription: type(of: self).description,
                    location: Location(
                        file: file,
                        byteOffset: offset
                    )
                )
            ]
        }
        return corrections
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
        dictionary: [String: SourceKitRepresentable]
    ) -> [(preferredModifier: ModifierDescription, declaredModifier: ModifierDescription)] {
        let violatableModifiers = self.violatableModifiers(declaredModifiers: dictionary.modifierDescriptions)
        let prioritizedModifiers = self.prioritizedModifiers(violatableModifiers: violatableModifiers)
        let sortedByPriorityModifiers = prioritizedModifiers
            .sorted { $0.priority < $1.priority }
            .map { $0.modifier }

        return zip(sortedByPriorityModifiers, violatableModifiers).filter { $0 != $1 }
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
                guard let offset = $0.offset else { return nil }
                if let attribute = $0.attribute,
                   let modifierGroup = SwiftDeclarationAttributeKind.ModifierGroup(rawAttribute: attribute),
                   let length = $0.length {
                    return ModifierDescription(
                        keyword: attribute.lastComponentAfter("."),
                        group: modifierGroup,
                        offset: offset,
                        length: length
                    )
                } else if let kind = $0.kind {
                    let keyword = kind.lastComponentAfter(".")
                    return ModifierDescription(
                        keyword: keyword,
                        group: .typeMethods,
                        offset: offset,
                        length: keyword.count
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
    func lastComponentAfter(_ character: String) -> String {
        return components(separatedBy: character).last ?? ""
    }
}

private struct ModifierDescription: Equatable {
    let keyword: String
    let group: SwiftDeclarationAttributeKind.ModifierGroup
    let offset: Int
    let length: Int
}
