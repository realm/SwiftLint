import Foundation
import SourceKittenFramework

struct ModifierOrderRule: ASTRule, OptInRule, CorrectableRule {
    var configuration = ModifierOrderConfiguration()

    static let description = RuleDescription(
        identifier: "modifier_order",
        name: "Modifier Order",
        description: "Modifier order should be consistent.",
        kind: .style,
        nonTriggeringExamples: ModifierOrderRuleExamples.nonTriggeringExamples,
        triggeringExamples: ModifierOrderRuleExamples.triggeringExamples
    )

    func validate(file: SwiftLintFile,
                  kind _: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let offset = dictionary.offset else {
            return []
        }

        let violatingModifiers = self.violatingModifiers(dictionary: dictionary)

        if let first = violatingModifiers.first {
            let preferredModifier = first.0
            let declaredModifier = first.1
            let reason = "\(preferredModifier.keyword) modifier should come before \(declaredModifier.keyword)"
            return [
                StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: reason
                ),
            ]
        }
        return []
    }

    func correct(file: SwiftLintFile) -> Int {
        file.structureDictionary.traverseDepthFirst { subDict in
            guard subDict.declarationKind != nil else {
                return [0]
            }
            return [correct(file: file, dictionary: subDict)]
        }.reduce(0, +)
    }
    private func correct(file: SwiftLintFile, dictionary: SourceKittenDictionary) -> Int {
        guard dictionary.offset != nil else {
            return 0
        }
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
        if violatingRanges.isEmpty {
            return 0
        }
        var correctedContents = originalContents.nsString
        violatingRanges.reversed().forEach { arg in
            let (preferredModifierRange, declaredModifierRange) = arg
            correctedContents = correctedContents.replacingCharacters(
                in: declaredModifierRange,
                with: originalContents.substring(with: preferredModifierRange)
            ).bridge()
        }
        file.write(correctedContents.bridge())
        return violatingRanges.count
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
            .map(\.modifier)

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
                }
                if let kind = $0.kind {
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
        guard let offset, let declarationKind, declarationKinds.contains(declarationKind) else {
            return nil
        }
        return SourceKittenDictionary(["key.kind": declarationKind.rawValue, "key.offset": Int64(offset.value)])
    }
}

private extension String {
    func lastComponentAfter(_ character: String) -> String {
        components(separatedBy: character).last ?? ""
    }
}

private struct ModifierDescription: Equatable {
    let keyword: String
    let group: SwiftDeclarationAttributeKind.ModifierGroup
    let offset: ByteCount
    let length: ByteCount
    var range: ByteRange { ByteRange(location: offset, length: length) }
}
