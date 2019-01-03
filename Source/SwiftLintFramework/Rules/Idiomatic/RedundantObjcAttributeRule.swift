import SourceKittenFramework

private let kindsImplyingObjc: Set<SwiftDeclarationAttributeKind> =
    [.ibaction, .iboutlet, .ibinspectable, .gkinspectable, .ibdesignable, .nsManaged]

private let privateACL: Set<SwiftDeclarationAttributeKind> = [.private, .fileprivate]

public struct RedundantObjcAttributeRule: ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_objc_attribute",
        name: "Redundant @objc Attribute",
        description: "Objective-C attribute (@objc) is redundant in declaration.",
        kind: .idiomatic,
        minSwiftVersion: .fourDotOne,
        nonTriggeringExamples: [
            "@objc private var foo: String? {}",
            "@IBInspectable private var foo: String? {}",
            "@objc private func foo(_ sender: Any) {}",
            "@IBAction private func foo(_ sender: Any) {}",
            "@GKInspectable private var foo: String! {}",
            "private @GKInspectable var foo: String! {}",
            "@NSManaged var foo: String!",
            "@objc @NSCopying var foo: String!",
            """
            @objcMembers
            class Foo {
              var bar: Any?
              @objc
              class Bar {
                @objc
                var foo: Any?
              }
            }
            """,
            """
            @objc
            extension Foo {
              var bar: Int {
                return 0
              }
            }
            """,
            """
            extension Foo {
              @objc
              var bar: Int { return 0 }
            }
            """,
            """
            @objc @IBDesignable
            extension Foo {
              var bar: Int { return 0 }
            }
            """,
            """
            @IBDesignable
            extension Foo {
              @objc
              var bar: Int { return 0 }
              var fooBar: Int { return 1 }
            }
            """,
            """
            @objcMembers
            class Foo: NSObject {
              @objc
              private var bar: Int {
                return 0
              }
            }
            """,
            """
            @objcMembers
            class Foo {
                class Bar: NSObject {
                    @objc var foo: Any
                }
            }
            """,
            """
            @objcMembers
            class Foo {
                @objc class Bar {}
            }
            """
        ],
        triggeringExamples: [
            "@objc @IBInspectable private ↓var foo: String? {}",
            "@IBInspectable @objc private ↓var foo: String? {}",
            "@objc @IBAction private ↓func foo(_ sender: Any) {}",
            "@IBAction @objc private ↓func foo(_ sender: Any) {}",
            "@objc @GKInspectable private ↓var foo: String! {}",
            "@GKInspectable @objc private ↓var foo: String! {}",
            "@objc @NSManaged private ↓var foo: String!",
            "@NSManaged @objc private ↓var foo: String!",
            "@objc @IBDesignable ↓class Foo {}",
            """
            @objcMembers
            class Foo {
              @objc ↓var bar: Any?
            }
            """,
            """
            @objcMembers
            class Foo {
              @objc ↓var bar: Any?
              @objc ↓var foo: Any?
              @objc
              class Bar {
                @objc
                var foo: Any?
              }
            }
            """,
            """
            @objc
            extension Foo {
              @objc
              ↓var bar: Int {
                return 0
              }
            }
            """,
            """
            @objc @IBDesignable
            extension Foo {
              @objc
              ↓var bar: Int {
                return 0
              }
            }
            """,
            """
            @objcMembers
            class Foo {
                @objcMembers
                class Bar: NSObject {
                    @objc ↓var foo: Any
                }
            }
            """,
            """
            @objc
            extension Foo {
                @objc
                private ↓var bar: Int {
                    return 0
                }
            }
            """
        ])

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file, dictionary: file.structure.dictionary, parentStructure: nil)
    }

    private func validate(file: File, dictionary: [String: SourceKitRepresentable],
                          parentStructure: [String: SourceKitRepresentable]?) -> [StyleViolation] {
        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict, parentStructure: dictionary)

            if let kindString = subDict.kind,
                let kind = SwiftDeclarationKind(rawValue: kindString) {
                violations += validate(file: file, kind: kind, dictionary: subDict, parentStructure: dictionary)
            }

            return violations
        }
    }

    private func validate(file: File,
                          kind: SwiftDeclarationKind,
                          dictionary: [String: SourceKitRepresentable],
                          parentStructure: [String: SourceKitRepresentable]?) -> [StyleViolation] {
        let enclosedSwiftAttributes = Set(dictionary.enclosedSwiftAttributes)
        guard let offset = dictionary.offset,
              enclosedSwiftAttributes.contains(.objc),
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

        let isUsedWithObjcAttribute = !enclosedSwiftAttributes.isDisjoint(with: kindsImplyingObjc)

        if isUsedWithObjcAttribute || isInObjcVisibleScope() {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))]
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
