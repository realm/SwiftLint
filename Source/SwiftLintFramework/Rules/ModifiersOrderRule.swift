//
//  ModifiersOrderRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ModifiersOrderRule: ASTRule, OptInRule, ConfigurationProviderRule {

    public var configuration = ModifiersOrderConfiguration(preferedModifiersOrder: [.override, .acl])

    public init() {}

    public static let description = RuleDescription(
        identifier: "modifiers_order",
        name: "Modifiers Order",
        description: "Modifiers order should be consistent.",
        kind: .style,
        nonTriggeringExamples: [
            "public static let nnumber = 3 \n",
            "@objc \npublic final class MyClass: NSObject {\n }",
            "@objc \n override public private(set) weak var foo: Bar?\n",
            "@objc \npublic final class MyClass: NSObject {\n }",
            "@objc \npublic final class MyClass: NSObject {\n" +
                "private final func myFinal() {}\n" +
                "weak var myWeak: NSString? = nil\n" +
            "public static let nnumber = 3 \n }",
            "public final class MyClass {}",
            "class RootClass { func myFinal() {}}\n" +
                "internal class MyClass: RootClass {" +
            "override internal func myFinal() {}}"
        ],
        triggeringExamples: [
            "class Foo { \n static public let bar = 3 {} \n }",
            "class Foo { \n class override public let bar = 3 {} \n }",
            "class Foo { \n overide static final public var foo: String {} \n }",
            "@objc \npublic final class MyClass: NSObject {\n" +
            "final private func myFinal() {}\n}",
            "@objc \nfinal public class MyClass: NSObject {}\n",
            "final public class MyClass {}\n",
            "class MyClass {" +
            "weak internal var myWeak: NSString? = nil\n}",
            "class MyClass {" +
            "static public let nnumber = 3 \n }"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard let offset = dictionary.offset else {
            return []
        }

        let preferedOrderOfModifiers = [.objcInteroperability, .interfaceBuilder] + configuration.preferedModifiersOrder
        print(preferedOrderOfModifiers)
        let modifierGroupsInDeclaration = findModifierGroups(in: dictionary)
        let filteredPreferedOrderOfModifiers = preferedOrderOfModifiers.filter {
            return modifierGroupsInDeclaration.contains($0)
        }
        print(filteredPreferedOrderOfModifiers)
        for (index, preferedGroup) in filteredPreferedOrderOfModifiers.enumerated()
            where preferedGroup != modifierGroupsInDeclaration[index] {
                return [StyleViolation(ruleDescription: type(of: self).description,
                                       severity: configuration.severityConfiguration.severity,
                                       location: Location(file: file, byteOffset: offset))]
        }

        return []
    }
    // swiftlint:disable line_length
    private func findModifierGroups(in dictionary: [String: SourceKitRepresentable]) -> [SwiftDeclarationAttributeKind.ModifierGroup] {

        var declarationAttributes = dictionary.enclosedSwiftAttributesWithMetaData
        if let delcarationKinds = contains(in: dictionary,
                                           declarationKinds: .functionMethodClass, .functionMethodStatic, .varClass, .varStatic) {
            declarationAttributes.append(delcarationKinds)
        }

        return declarationAttributes
            .sorted {
                guard let rhsOffset = $0["key.offset"] as? Int64,
                      let lhsOffset = $1["key.offset"] as? Int64 else {
                    return false

                }
                return rhsOffset < lhsOffset
            }
            .compactMap {
                if let attribute = $0["key.attribute"] as? String { return group(of: attribute) }
                if $0["key.kind"] != nil { return .typeMethods }
                return nil
            }
    }

    private func group(of rawAttribute: String) -> SwiftDeclarationAttributeKind.ModifierGroup? {
        for value in SwiftDeclarationAttributeKind.ModifierGroup.allValues {
            for attributeKind in value.swiftDeclarationAttributeKinds
                where attributeKind.rawValue.hasSuffix(rawAttribute) {
                return value
            }
        }

        if rawAttribute == "static" || rawAttribute == "class" {
            return .typeMethods
        }

        return nil
    }

    private func contains(in dictionary: [String: SourceKitRepresentable],
                          declarationKinds: SwiftDeclarationKind...) -> [String: SourceKitRepresentable]? {
        guard let rawKind = dictionary.kind,
            let kind = SwiftDeclarationKind(rawValue: rawKind),
            let offset = dictionary.offset else { return nil }
        if declarationKinds.contains(kind) { return ["key.kind": rawKind, "key.offset": Int64(offset)] }
        return nil
    }
}
