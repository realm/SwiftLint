import Foundation
import SourceKittenFramework

public struct ExtensionAccessModifierRule: ASTRule, ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "extension_access_modifier",
        name: "Extension Access Modifier",
        description: "Prefer to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: [
            """
            extension Foo: SomeProtocol {
              public var bar: Int { return 1 }
            }
            """,
            """
            extension Foo {
              private var bar: Int { return 1 }
              public var baz: Int { return 1 }
            }
            """,
            """
            extension Foo {
              private var bar: Int { return 1 }
              public func baz() {}
            }
            """,
            """
            extension Foo {
              var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """,
            """
            public extension Foo {
              var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """,
            """
            extension Foo {
              private bar: Int { return 1 }
              private baz: Int { return 1 }
            }
            """,
            """
            extension Foo {
              open bar: Int { return 1 }
              open baz: Int { return 1 }
            }
            """
        ],
        triggeringExamples: [
            """
            ↓extension Foo {
               public var bar: Int { return 1 }
               public var baz: Int { return 1 }
            }
            """,
            """
            ↓extension Foo {
               public var bar: Int { return 1 }
               public func baz() {}
            }
            """,
            """
            public extension Foo {
               public ↓func bar() {}
               public ↓func baz() {}
            }
            """
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .extension, let offset = dictionary.offset,
            dictionary.inheritedTypes.isEmpty else {
                return []
        }

        let declarations = dictionary.substructure.compactMap { entry -> (acl: AccessControlLevel, offset: Int)? in
            guard entry.declarationKind != nil,
                let acl = entry.accessibility,
                let offset = entry.offset else {
                return nil
            }

            return (acl: acl, offset: offset)
        }

        let declarationsACLs = declarations.map { $0.acl }.unique
        let allowedACLs: Set<AccessControlLevel> = [.internal, .private, .open]
        guard declarationsACLs.count == 1, !allowedACLs.contains(declarationsACLs[0]) else {
            return []
        }

        let syntaxTokens = file.syntaxMap.tokens
        let parts = syntaxTokens.partitioned { offset <= $0.offset }
        if let aclToken = parts.first.last, file.isACL(token: aclToken) {
            return declarationsViolations(file: file, acl: declarationsACLs[0],
                                          declarationOffsets: declarations.map { $0.offset },
                                          dictionary: dictionary)
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func declarationsViolations(file: SwiftLintFile, acl: AccessControlLevel,
                                        declarationOffsets: [Int],
                                        dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let offset = dictionary.offset, let length = dictionary.length,
            case let contents = file.linesContainer,
            let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                return []
        }

        // find all ACL tokens
        let allACLRanges = file.match(pattern: acl.description, with: [.attributeBuiltin], range: range).compactMap {
            contents.NSRangeToByteRange(start: $0.location, length: $0.length)
        }

        let violationOffsets = declarationOffsets.filter { typeOffset in
            // find the last ACL token before the type
            guard let previousInternalByteRange = lastACLByteRange(before: typeOffset, in: allACLRanges) else {
                // didn't find a candidate token, so the ACL is implict (not a violation)
                return false
            }

            // the ACL token correspond to the type if there're only
            // attributeBuiltin (`final` for example) tokens between them
            let length = typeOffset - previousInternalByteRange.location
            let range = NSRange(location: previousInternalByteRange.location, length: length)
            let internalBelongsToType = Set(file.syntaxMap.kinds(inByteRange: range)) == [.attributeBuiltin]

            return internalBelongsToType
        }

        return violationOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func lastACLByteRange(before typeOffset: Int, in ranges: [NSRange]) -> NSRange? {
        let firstPartition = ranges.partitioned(by: { $0.location > typeOffset }).first
        return firstPartition.last
    }
}
