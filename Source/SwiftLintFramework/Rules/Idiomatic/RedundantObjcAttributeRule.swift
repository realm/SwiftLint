import Foundation
import SourceKittenFramework

private let kindsImplyingObjc: Set<SwiftDeclarationAttributeKind> =
    [.ibaction, .iboutlet, .ibinspectable, .gkinspectable, .ibdesignable, .nsManaged]

public struct RedundantObjcAttributeRule: SubstitutionCorrectableRule, ConfigurationProviderRule,
    AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_objc_attribute",
        name: "Redundant @objc Attribute",
        description: "Objective-C attribute (@objc) is redundant in declaration.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: RedundantObjcAttributeRuleExamples.nonTriggeringExamples,
        triggeringExamples: RedundantObjcAttributeRuleExamples.triggeringExamples,
        corrections: RedundantObjcAttributeRuleExamples.corrections)

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(file: file, dictionary: file.structure.dictionary, parentStructure: nil)
    }

    private func violationRanges(file: File, dictionary: [String: SourceKitRepresentable],
                                 parentStructure: [String: SourceKitRepresentable]?) -> [NSRange] {
        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            var violations = violationRanges(file: file, dictionary: subDict, parentStructure: dictionary)

            if let kindString = subDict.kind,
                let kind = SwiftDeclarationKind(rawValue: kindString) {
                violations += violationRanges(file: file, kind: kind, dictionary: subDict, parentStructure: dictionary)
            }

            return violations
        }
    }

    private func violationRanges(file: File,
                                 kind: SwiftDeclarationKind,
                                 dictionary: [String: SourceKitRepresentable],
                                 parentStructure: [String: SourceKitRepresentable]?) -> [NSRange] {
        let objcAttribute = dictionary.swiftAttributes
                                      .first(where: { $0.attribute == SwiftDeclarationAttributeKind.objc.rawValue })
        guard let objcOffset = objcAttribute?.offset,
              let objcLength = objcAttribute?.length,
              let range = file.contents.bridge().byteRangeToNSRange(start: objcOffset, length: objcLength),
              !dictionary.isObjcAndIBDesignableDeclaredExtension else {
            return []
        }

        let isInObjcVisibleScope = { () -> Bool in
            guard let parentStructure = parentStructure,
                let kind = dictionary.kind.flatMap(SwiftDeclarationKind.init),
                let parentKind = parentStructure.kind.flatMap(SwiftDeclarationKind.init),
                let acl = dictionary.accessibility.flatMap(AccessControlLevel.init(identifier:)) else {
                    return false
            }

            let isInObjCExtension = [.extensionClass, .extension].contains(parentKind) &&
                parentStructure.enclosedSwiftAttributes.contains(.objc)

            let isInObjcMembers = parentStructure.enclosedSwiftAttributes.contains(.objcMembers) && !acl.isPrivate

            guard isInObjCExtension || isInObjcMembers else {
                return false
            }

            return !SwiftDeclarationKind.typeKinds.contains(kind)
        }

        let isUsedWithObjcAttribute = !Set(dictionary.enclosedSwiftAttributes).isDisjoint(with: kindsImplyingObjc)

        if isUsedWithObjcAttribute || isInObjcVisibleScope() {
            return [range]
        }

        return []
    }
}

private extension Dictionary where Key == String, Value == SourceKitRepresentable {
    var isObjcAndIBDesignableDeclaredExtension: Bool {
        guard let kind = kind, let declaration = SwiftDeclarationKind(rawValue: kind) else {
            return false
        }
        return [.extensionClass, .extension].contains(declaration)
            && Set(enclosedSwiftAttributes).isSuperset(of: [.ibdesignable, .objc])
    }
}

public extension RedundantObjcAttributeRule {
     func substitution(for violationRange: NSRange, in file: File) -> (NSRange, String) {
        var whitespaceAndNewlineOffset = 0
        let nsCharSet = CharacterSet.whitespacesAndNewlines.bridge()
        let nsContent = file.contents.bridge()
        while nsCharSet
            .characterIsMember(nsContent.character(at: violationRange.upperBound + whitespaceAndNewlineOffset)) {
                whitespaceAndNewlineOffset += 1
        }

        let withTrailingWhitespaceAndNewlineRange = NSRange(location: violationRange.location,
                                                            length: violationRange.length + whitespaceAndNewlineOffset)
        return (withTrailingWhitespaceAndNewlineRange, "")
    }
}
