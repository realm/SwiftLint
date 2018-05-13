import Foundation
import SourceKittenFramework

public struct RedundantObjcAttributeRule: ASTRule, ConfigurationProviderRule {

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
            "@objcMembers\n"                    +
            "class Foo {\n"                     +
            "   var bar: Any?\n"                +
            "   @objc\n"                        +
            "   class Bar {\n"                  +
            "       @objc\n"                    +
            "       var foo: Any?\n"            +
            "   }\n"                            +
            "}",
            "@objc\n"                           +
            "extension Foo {\n"                 +
            "   var bar: Int {\n"               +
            "       return 0\n"                 +
            "   }\n"                            +
            "}",
            "extension Foo {\n"                 +
            "   @objc\n"                        +
            "   var bar: Int { return 0 }\n"    +
            "}",
            "@objc @IBDesignable\n"             +
            "extension Foo {\n"                 +
            "   var bar: Int { return 0 }\n"    +
            "}",
            "@IBDesignable\n"                   +
            "extension Foo {\n"                 +
            "   @objc\n"                        +
            "   var bar: Int { return 0 }\n"    +
            "   var fooBar: Int { return 1 }\n" +
            "}"
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
            "@objcMembers\n"                    +
            "class Foo {\n"                     +
            "   @objc ↓var bar: Any?\n"         +
            "}",
            "@objcMembers\n"                    +
            "class Foo {\n"                     +
            "   @objc ↓var bar: Any?\n"         +
            "   @objc ↓var foo: Any?\n"         +
            "   @objc\n"                        +
            "   class Bar {\n"                  +
            "       @objc\n"                    +
            "       var foo: Any?\n"            +
            "   }\n"                            +
            "}",
            "@objc\n"                           +
            "extension Foo {\n"                 +
            "   @objc\n"                        +
            "   ↓var bar: Int {\n"              +
            "       return 0\n"                 +
            "    }\n"                           +
            "}",
            "@objc @IBDesignable\n"             +
            "extension Foo {\n"                 +
                "   @objc\n"                    +
                "   ↓var bar: Int {\n"          +
                "       return 0\n"             +
                "    }\n"                       +
            "}"
        ])

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard let offset = dictionary.offset,
              dictionary.enclosedSwiftAttributes.contains(.objc),
              !dictionary.isObjcAndIBDesiganableDeclaredExtension else {
            return []
        }

        let isInObjcVisibleScope = file.structure.dictionary.objcVisibleRanges.contains(where: { $0.contains(offset) })
        let isUsedWithObjcAttribute = dictionary.enclosedSwiftAttributes.contains(where: { [.ibaction,
                                                                                            .iboutlet,
                                                                                            .ibinspectable,
                                                                                            .gkinspectable,
                                                                                            .ibdesignable,
                                                                                            .nsManaged].contains($0) })

        if isInObjcVisibleScope || isUsedWithObjcAttribute {
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
            if let enclosedObjcMembersRange = dictionary.enclosedObjcMembersRange {
                ranges.append(enclosedObjcMembersRange)
            }

            if let enclosedObjcExtensionRange = dictionary.enclosedObjcExtensionRange {
                ranges.append(enclosedObjcExtensionRange)
            }

            if let enclosedNonObjcMembersClassRange = dictionary.enclosedNonObjcMembersClassRange {
                let intersectingRanges = ranges.filter { $0.intersects(enclosedNonObjcMembersClassRange) }
                intersectingRanges.compactMap { ranges.index(of: $0) }
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

    var enclosedObjcExtensionRange: NSRange? {
        guard let kind = kind,
            let declaration = SwiftDeclarationKind(rawValue: kind),
            declaration == .extensionClass || declaration == .extension,
            enclosedSwiftAttributes.contains(.objc),
            let bodyOffset = bodyOffset,
            let bodyLength = bodyLength else {
                return nil
        }
        return NSRange(location: bodyOffset, length: bodyLength)
    }

    var enclosedObjcMembersRange: NSRange? {
        guard enclosedSwiftAttributes.contains(.objcMembers),
            let bodyOffset = bodyOffset,
            let bodyLength = bodyLength else {
                return nil
        }
        return NSRange(location: bodyOffset, length: bodyLength)
    }

    var enclosedNonObjcMembersClassRange: NSRange? {
        guard let kind = kind,
            let declaration = SwiftDeclarationKind(rawValue: kind),
            declaration == .class,
            !enclosedSwiftAttributes.contains(.objcMembers),
            let offset = offset,
            let bodyLength = bodyLength else {
                return nil
        }
        return NSRange(location: offset, length: bodyLength)
    }

    var isObjcAndIBDesiganableDeclaredExtension: Bool {
        guard let kind = kind,
             let declaration = SwiftDeclarationKind(rawValue: kind) else {
                return false
        }
        return (declaration == .extensionClass || declaration == .extension)
            && enclosedSwiftAttributes.contains(.ibdesignable)
            && enclosedSwiftAttributes.contains(.objc)
    }
}

private extension NSRange {
    func split(by range: NSRange) -> (lhs: NSRange, rhs: NSRange) {
        return (NSRange(location: location, length: range.location - location),
                NSRange(location: (range.location + range.length),
                        length: location + length - (range.location + range.length)))
    }
}
