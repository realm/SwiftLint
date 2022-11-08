import Foundation
import SourceKittenFramework

struct ModifierOrderRule: ASTRule, OptInRule, ConfigurationProviderRule, CorrectableRule {
    var configuration = ModifierOrderConfiguration(
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

    init() {}

    static let description = RuleDescription(
        identifier: "modifier_order",
        name: "Modifier Order",
        description: "Modifier order should be consistent.",
        kind: .style,
        nonTriggeringExamples: ModifierOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ModifierOrderRuleExamples.triggeringExamples
    )

    func validate(file: SwiftLintFile,
                  kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
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
                    ruleDescription: Self.description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: reason
                )
            ]
        } else {
            return []
        }
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        return file.structureDictionary.traverseDepthFirst { subDict in
            guard let kind = subDict.declarationKind else { return nil }
            return correct(file: file, kind: kind, dictionary: subDict)
        }
    }
    private func correct(file: SwiftLintFile,
                         kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [Correction] {
        guard let offset = dictionary.offset else { return [] }
        let originalContents = file.stringView
        let violatingRanges = violatingModifiers(dictionary: dictionary)
            .compactMap { preferred, declared -> (NSRange, NSRange)? in
                guard
                    let preferredRange = originalContents.byteRangeToNSRange(
                        preferred.range
                    ).flatMap({ file.ruleEnabled(violatingRange: $0, for: self) }),
                    let declaredRange = originalContents.byteRangeToNSRange(
                        declared.range
                    ).flatMap({ file.ruleEnabled(violatingRange: $0, for: self) })
                else {
                    return nil
                }
                return (preferredRange, declaredRange)
            }

        let corrections: [Correction]
        if violatingRanges.isEmpty {
            corrections = []
        } else {
            var correctedContents = originalContents.nsString

            violatingRanges.reversed().forEach { arg in
                let (preferredModifierRange, declaredModifierRange) = arg
                correctedContents = correctedContents.replacingCharacters(
                    in: declaredModifierRange,
                    with: originalContents.substring(with: preferredModifierRange)
                ).bridge()
            }

            file.write(correctedContents.bridge())

            corrections = [
                Correction(
                    ruleDescription: Self.description,
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
        dictionary: SourceKittenDictionary
    ) -> [(preferredModifier: ModifierDescription, declaredModifier: ModifierDescription)] {
        let violatableModifiers = self.violatableModifiers(declaredModifiers: dictionary.modifierDescriptions)
        let prioritizedModifiers = self.prioritizedModifiers(violatableModifiers: violatableModifiers)
        let sortedByPriorityModifiers = prioritizedModifiers
            .sorted { $0.priority < $1.priority }
            .map { $0.modifier }

        return zip(sortedByPriorityModifiers, violatableModifiers).filter { $0 != $1 }
    }
}

private extension SourceKittenDictionary {
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
                        length: ByteCount(keyword.lengthOfBytes(using: .utf8))
                    )
                }
                return nil
            }
    }

    private func kindsAndOffsets(in declarationKinds: [SwiftDeclarationKind]) -> SourceKittenDictionary? {
        guard let offset = offset,
            let declarationKind = declarationKind,
            declarationKinds.contains(declarationKind)
        else {
            return nil
        }

        return SourceKittenDictionary(["key.kind": declarationKind.rawValue, "key.offset": Int64(offset.value)])
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
    let offset: ByteCount
    let length: ByteCount
    var range: ByteRange { return ByteRange(location: offset, length: length) }
}
