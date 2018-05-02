//
//  ModifierOrderRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/06/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import SourceKittenFramework

// swiftlint:disable type_body_length
public struct ModifierOrderRule: ASTRule, OptInRule, ConfigurationProviderRule {

    public var configuration = ModifierOrderConfiguration(preferedModifierOrder: [.override, .acl])

    public init() {}

    public static let description = RuleDescription(
        identifier: "modifier_order",
        name: "Modifier Order",
        description: "Modifier order should be consistent.",
        kind: .style,
        minSwiftVersion: .fourDotOne ,
        nonTriggeringExamples: [
            "public class Foo { \n"                                 +
            "   public convenience required init() {} \n"           +
            "}",
            "public class Foo { \n"                                 +
            "   public static let bar = 42 \n"                      +
            "}",
            "public class Foo { \n"                                 +
            "   public static var bar: Int { \n"                    +
            "       return 42"                                      +
            "   }"                                                  +
            "}",
            "public class Foo { \n"                                 +
            "   public class var bar: Int { \n"                     +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "}",
            "public class Bar { \n"                                 +
            "   public class var foo: String { \n"                  +
            "       return \"foo\" \n"                              +
            "   } \n"                                               +
            "} \n"                                                  +
            "public class Foo: Bar { \n"                            +
            "   override public final class var foo: String { \n"   +
            "       return \"bar\" \n"                              +
            "   } \n"                                               +
            "}",
            "open class Bar { \n"                                   +
            "   public var foo: Int? { \n"                          +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "} \n"                                                  +
            "open class Foo: Bar { \n"                              +
            "   override public var foo: Int? { \n"                 +
            "       return 43 \n"                                   +
            "   } \n"                                               +
            "}",
            "open class Bar { \n"                                   +
            "   open class func foo() -> Int { \n"                  +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "} \n"                                                  +
            "class Foo: Bar { \n"                                   +
            "   override open class func foo() -> Int { \n"         +
            "       return 43 \n"                                   +
            "   } \n"                                               +
            "}",
            "protocol Foo: class {} \n"                             +
            "class Bar { \n"                                        +
            "    public private(set) weak var foo: Foo? \n"         +
            "} \n",
            "@objc \n"                                              +
            "public final class Foo: NSObject {} \n",
            "@objcMembers \n"                                       +
            "public final class Foo: NSObject {} \n",
            "@objc \n"                                              +
            "override public private(set) weak var foo: Bar? \n",
            "@objc \n"                                              +
            "public final class Foo: NSObject {} \n",
            "@objc \n"                                              +
            "open final class Foo: NSObject { \n"                   +
            "   open weak var weakBar: NSString? = nil \n"          +
            "}",
            "public final class Foo {}",
            "class Bar { \n"                                        +
            "   func bar() {} \n"                                   +
            "}",
            "internal class Foo: Bar { \n"                          +
            "   override internal func bar() {} \n"                 +
            "}",
            "public struct Foo { \n"                                +
            "   internal weak var weakBar: NSObject? = nil \n"      +
            "}",
            "class Foo { \n"                                        +
            "   internal lazy var bar: String = \"foo\" \n"         +
            "}"
        ],
        triggeringExamples: [
            "class Foo { \n"                                        +
            "   convenience required public init() {} \n"           +
            "}",
            "public class Foo { \n"                                 +
            "   static public let bar = 42 \n"                      +
            "}",
            "public class Foo { \n"                                 +
            "   static public var bar: Int { \n"                    +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "} \n",
            "public class Foo { \n"                                 +
            "   class public var bar: Int { \n"                     +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "}",
            "public class RootFoo { \n"                             +
            "   class public var foo: String { \n"                  +
            "       return \"foo\" \n"                              +
            "   } \n"                                               +
            "} \n"                                                  +
            "public class Foo: RootFoo { \n"                        +
            "   override final class public var foo: String { \n"   +
            "       return \"bar\" \n"                              +
            "   } \n"                                               +
            "}",
            "open class Bar { \n"                                   +
            "   public var foo: Int? { \n"                          +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "} \n"                                                  +
            "open class Foo: Bar { \n"                              +
            "    public override var foo: Int? { \n"                +
            "       return 43 \n"                                   +
            "   } \n"                                               +
            "}",
            "protocol Foo: class {} \n"                             +
                "class Bar { \n"                                    +
                "    private(set) public weak var foo: Foo? \n"     +
            "} \n",
            "open class Bar { \n"                                   +
            "   open class func foo() -> Int { \n"                  +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "} \n"                                                  +
            "class Foo: Bar { \n"                                   +
            "   class open override func foo() -> Int { \n"         +
            "       return 43 \n"                                   +
            "   } \n"                                               +
            "}",
            "open class Bar { \n"                                   +
            "   open class func foo() -> Int { \n"                  +
            "       return 42 \n"                                   +
            "   } \n"                                               +
            "} \n"                                                  +
            "class Foo: Bar { \n"                                   +
            "   open override class func foo() -> Int { \n"         +
            "       return 43 \n"                                   +
            "   } \n"                                               +
            "}",
            "@objc \n"                                              +
            "final public class Foo: NSObject {}",
            "@objcMembers \n"                                       +
            "final public class Foo: NSObject {}",
            "@objc \n"                                              +
            "final open class Foo: NSObject { \n"                   +
            "   weak open var weakBar: NSString? = nil \n"          +
            "}",
            "final public class Foo {} \n",
            "internal class Foo: Bar { \n"                          +
            "   internal override func bar() {} \n"                 +
            "}",
            "public struct Foo { \n"                                +
            "   weak internal var weakBar: NSObjetc? = nil \n"      +
            "}",
            "class Foo { \n"                                        +
            "   lazy internal var bar: String = \"foo\" \n"         +
            "}"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard let offset = dictionary.offset else {
            return []
        }

        let preferedOrderOfModifiers = [.atPrefixed] + configuration.preferedModifierOrder
        let modifierGroupsInDeclaration = findModifierGroups(in: dictionary)
        let filteredPreferedOrderOfModifiers = preferedOrderOfModifiers.filter(modifierGroupsInDeclaration.contains)
        for (index, preferedGroup) in filteredPreferedOrderOfModifiers.enumerated()
            where preferedGroup != modifierGroupsInDeclaration[index] {
                return [StyleViolation(ruleDescription: type(of: self).description,
                                       severity: configuration.severityConfiguration.severity,
                                       location: Location(file: file, byteOffset: offset))]
        }

        return []
    }

    private func findModifierGroups(in dictionary: [String: SourceKitRepresentable])
        -> [SwiftDeclarationAttributeKind.ModifierGroup] {

            var declarationAttributes = dictionary.swiftAttributes
        let kinds = [SwiftDeclarationKind.functionMethodClass, .functionMethodStatic, .varClass, .varStatic]
        if let delcarationKinds = contains(in: dictionary, declarationKinds: kinds) {
            declarationAttributes.append(delcarationKinds)
        }
        return declarationAttributes
            .sorted {
                guard let rhsOffset = $0.offset, let lhsOffset = $1.offset else {
                    return false
                }
                return rhsOffset < lhsOffset
            }
            .compactMap {
                if let attribute = $0.attribute { return group(of: attribute) }
                if $0.kind != nil { return .typeMethods }
                return nil
            }
    }

    private func group(of rawAttribute: String) -> SwiftDeclarationAttributeKind.ModifierGroup? {
        let allModifierGroups: Set<SwiftDeclarationAttributeKind.ModifierGroup> = [
            .acl, .setterACL, .mutators, .override, .owned, .atPrefixed, .dynamic, .final, .typeMethods,
            .required, .convenience, .lazy
        ]
        return allModifierGroups.first {
            $0.swiftDeclarationAttributeKinds.contains(where: { $0.rawValue == rawAttribute })
        }
    }

    private func contains(in dictionary: [String: SourceKitRepresentable],
                          declarationKinds: [SwiftDeclarationKind]) -> [String: SourceKitRepresentable]? {
        guard let rawKind = dictionary.kind,
            let kind = SwiftDeclarationKind(rawValue: rawKind),
            let offset = dictionary.offset else {
                return nil
        }

        if declarationKinds.contains(kind) {
            return ["key.kind": rawKind, "key.offset": Int64(offset)]
        }

        return nil
    }
}
