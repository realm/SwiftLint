import Foundation
import SourceKittenFramework

public struct ExplicitTopLevelACLRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_top_level_acl",
        name: "Explicit Top Level ACL",
        description: "Top-level declarations should specify Access Control Level keywords explicitly.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "internal enum A {}\n",
            "public final class B {}\n",
            "private struct C {}\n",
            "internal enum A {\n enum B {}\n}",
            "internal final class Foo {}",
            "internal\nclass Foo {}",
            "internal func a() {}\n",
            "extension A: Equatable {}",
            "extension A {}"
        ],
        triggeringExamples: [
            "enum A {}\n",
            "final class B {}\n",
            "struct C {}\n",
            "func a() {}\n",
            "internal let a = 0\nfunc b() {}\n"
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let extensionKinds: Set<SwiftDeclarationKind> = [.extension, .extensionClass, .extensionEnum,
                                                         .extensionProtocol, .extensionStruct]

        // find all top-level types marked as internal (either explictly or implictly)
        let dictionary = file.structureDictionary
        let internalTypesOffsets = dictionary.substructure.compactMap { element -> Int? in
            // ignore extensions
            guard let kind = element.declarationKind,
                !extensionKinds.contains(kind) else {
                    return nil
            }

            if element.accessibility == .internal {
                return element.offset
            }

            return nil
        }

        guard !internalTypesOffsets.isEmpty else {
            return []
        }

        // find all "internal" tokens
        let contents = file.linesContainer
        let allInternalRanges = file.match(pattern: "internal", with: [.attributeBuiltin]).compactMap {
            contents.NSRangeToByteRange(start: $0.location, length: $0.length)
        }

        let violationOffsets = internalTypesOffsets.filter { typeOffset in
            // find the last "internal" token before the type
            guard let previousInternalByteRange = lastInternalByteRange(before: typeOffset,
                                                                        in: allInternalRanges) else {
                // didn't find a candidate token, so we are sure it's a violation
                return true
            }

            // the "internal" token correspond to the type if there're only
            // attributeBuiltin (`final` for example) tokens between them
            let length = typeOffset - previousInternalByteRange.location
            let range = NSRange(location: previousInternalByteRange.location, length: length)
            let internalDoesntBelongToType = Set(file.syntaxMap.kinds(inByteRange: range)) != [.attributeBuiltin]

            return internalDoesntBelongToType
        }

        return violationOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func lastInternalByteRange(before typeOffset: Int, in ranges: [NSRange]) -> NSRange? {
        let firstPartition = ranges.prefix(while: { typeOffset > $0.location })
        return firstPartition.last
    }
}
