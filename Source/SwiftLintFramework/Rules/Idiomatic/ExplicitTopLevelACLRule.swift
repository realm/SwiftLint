import Foundation
import SourceKittenFramework

public struct ExplicitTopLevelACLRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_top_level_acl",
        name: "Explicit Top Level ACL",
        description: "Top-level declarations should specify Access Control Level keywords explicitly.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("internal enum A {}\n"),
            Example("public final class B {}\n"),
            Example("private struct C {}\n"),
            Example("internal enum A {\n enum B {}\n}"),
            Example("internal final class Foo {}"),
            Example("internal\nclass Foo {}"),
            Example("internal func a() {}\n"),
            Example("extension A: Equatable {}"),
            Example("extension A {}")
        ],
        triggeringExamples: [
            Example("enum A {}\n"),
            Example("final class B {}\n"),
            Example("struct C {}\n"),
            Example("func a() {}\n"),
            Example("internal let a = 0\nfunc b() {}\n")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        // find all top-level types marked as internal (either explicitly or implicitly)
        let dictionary = file.structureDictionary
        let internalTypesOffsets = dictionary.substructure.compactMap { element -> ByteCount? in
            // ignore extensions
            guard let kind = element.declarationKind,
                !SwiftDeclarationKind.extensionKinds.contains(kind) else {
                    return nil
            }

            if element.accessibility == .internal {
                return element.offset
            }

            return nil
        }

        guard internalTypesOffsets.isNotEmpty else {
            return []
        }

        // find all "internal" tokens
        let contents = file.stringView
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
            let range = ByteRange(location: previousInternalByteRange.location, length: length)
            let internalDoesntBelongToType = Set(file.syntaxMap.kinds(inByteRange: range)) != [.attributeBuiltin]

            return internalDoesntBelongToType
        }

        return violationOffsets.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func lastInternalByteRange(before typeOffset: ByteCount, in ranges: [ByteRange]) -> ByteRange? {
        let firstPartition = ranges.prefix(while: { typeOffset > $0.location })
        return firstPartition.last
    }
}
