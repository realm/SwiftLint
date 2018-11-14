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

private final class ModifierDescription: Equatable {
    let keyword: String
    let group: SwiftDeclarationAttributeKind.ModifierGroup

    init(
        keyword: String,
        group: SwiftDeclarationAttributeKind.ModifierGroup
    ) {
        self.keyword = keyword
        self.group = group
    }

    static func == (lhs: ModifierDescription, rhs: ModifierDescription) -> Bool {
        return lhs.keyword == rhs.keyword
            && lhs.group == rhs.group
    }
}
