import Foundation
import SourceKittenFramework

private let kindsImplyingObjc: Set<SwiftDeclarationAttributeKind> =
    [.ibaction, .iboutlet, .ibinspectable, .gkinspectable, .ibdesignable, .nsManaged]

public struct RedundantObjcAttributeRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "redundant_objc_attribute",
        name: "Redundant @objc Attribute",
        description: "Objective-C attribute (@objc) is redundant in declaration.",
        kind: .idiomatic,
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
            """
        ])

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        let enclosedSwiftAttributes = Set(dictionary.enclosedSwiftAttributes)
        guard let offset = dictionary.offset,
              enclosedSwiftAttributes.contains(.objc),
              !dictionary.isObjcAndIBDesignableDeclaredExtension else {
            return []
        }

        let isInObjcVisibleScope = {
            file.structure.dictionary.objcVisibleRanges.contains(where: { $0.contains(offset) })
        }

        let isUsedWithObjcAttribute = { !enclosedSwiftAttributes.isDisjoint(with: kindsImplyingObjc) }

        if isInObjcVisibleScope() || isUsedWithObjcAttribute() {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))]
        }

        return []
    }
}

private extension Dictionary where Key == String, Value == SourceKitRepresentable {

    var objcVisibleRanges: [NSRange] {
        var ranges = [NSRange]()
        func search(in dictionary: [String: SourceKitRepresentable]) {
            let enclosedRanges = [dictionary.enclosedObjcMembersRange, dictionary.enclosedObjcExtensionRange]
            ranges.append(contentsOf: enclosedRanges.compactMap({ $0 }))

            if let enclosedNonObjcMembersClassRange = dictionary.enclosedNonObjcMembersClassRange {
                let intersectingRanges = ranges.filter { $0.intersects(enclosedNonObjcMembersClassRange) }
                intersectingRanges.compactMap(ranges.index(of:))
                                  .forEach { ranges.remove(at: $0) }

                intersectingRanges.forEach {
                    let (lhs, rhs) = $0.split(by: enclosedNonObjcMembersClassRange)
                    ranges += [lhs, rhs]
                }
            }

            dictionary.substructure.forEach(search)
        }
        search(in: self)
        return ranges
    }

    var bodyRange: NSRange? {
        guard let bodyOffset = bodyOffset, let bodyLength = bodyLength else {
            return nil
        }
        return NSRange(location: bodyOffset, length: bodyLength)
    }

    var enclosedObjcExtensionRange: NSRange? {
        guard let kind = kind,
            let declaration = SwiftDeclarationKind(rawValue: kind),
            [.extensionClass, .extension].contains(declaration),
            enclosedSwiftAttributes.contains(.objc),
            let bodyRange = bodyRange else {
                return nil
        }
        return bodyRange
    }

    var enclosedObjcMembersRange: NSRange? {
        guard enclosedSwiftAttributes.contains(.objcMembers), let bodyRange = bodyRange else {
            return nil
        }
        return bodyRange
    }

    var enclosedNonObjcMembersClassRange: NSRange? {
        guard let kind = kind,
            SwiftDeclarationKind(rawValue: kind) == .class,
            !enclosedSwiftAttributes.contains(.objcMembers),
            let offset = offset,
            let bodyLength = bodyLength else {
                return nil
        }
        return NSRange(location: offset, length: bodyLength)
    }

    var isObjcAndIBDesignableDeclaredExtension: Bool {
        guard let kind = kind, let declaration = SwiftDeclarationKind(rawValue: kind) else {
            return false
        }
        return [.extensionClass, .extension].contains(declaration)
            && Set(enclosedSwiftAttributes).isSuperset(of: [.ibdesignable, .objc])
    }
}

private extension NSRange {
    func split(by range: NSRange) -> (lhs: NSRange, rhs: NSRange) {
        return (NSRange(location: location, length: range.location - location),
                NSRange(location: (range.location + range.length),
                        length: location + length - (range.location + range.length)))
    }
}
