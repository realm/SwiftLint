import Foundation
import SourceKittenFramework

struct ExtensionAccessModifierRule: ASTRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "extension_access_modifier",
        name: "Extension Access Modifier",
        description: "Prefer to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            extension Foo: SomeProtocol {
              public var bar: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              private var bar: Int { return 1 }
              public var baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              private var bar: Int { return 1 }
              public func baz() {}
            }
            """),
            Example("""
            extension Foo {
              var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """),
            Example("""
            public extension Foo {
              var bar: Int { return 1 }
              var baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              private bar: Int { return 1 }
              private baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
              open bar: Int { return 1 }
              open baz: Int { return 1 }
            }
            """),
            Example("""
            extension Foo {
                func setup() {}
                public func update() {}
            }
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓extension Foo {
               public var bar: Int { return 1 }
               public var baz: Int { return 1 }
            }
            """),
            Example("""
            ↓extension Foo {
               public var bar: Int { return 1 }
               public func baz() {}
            }
            """),
            Example("""
            public extension Foo {
               public ↓func bar() {}
               public ↓func baz() {}
            }
            """),
            Example("""
            ↓extension Foo {
               public var bar: Int {
                  let value = 1
                  return value
               }

               public var baz: Int { return 1 }
            }
            """)
        ]
    )

    func validate(file: SwiftLintFile, kind: SwiftDeclarationKind,
                  dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .extension, let offset = dictionary.offset,
            dictionary.inheritedTypes.isEmpty
        else {
            return []
        }

        let declarations = dictionary.substructure
            .compactMap { entry -> (acl: AccessControlLevel, offset: ByteCount)? in
                guard let kind = entry.declarationKind,
                      kind != .varLocal, kind != .varParameter,
                      let offset = entry.offset else {
                    return nil
                }

                return (acl: entry.accessibility ?? .internal, offset: offset)
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
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func declarationsViolations(file: SwiftLintFile, acl: AccessControlLevel,
                                        declarationOffsets: [ByteCount],
                                        dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard let byteRange = dictionary.byteRange,
            case let contents = file.stringView,
            let range = contents.byteRangeToNSRange(byteRange) else {
                return []
        }

        // find all ACL tokens
        let allACLRanges = file.match(pattern: acl.description, with: [.attributeBuiltin], range: range).compactMap {
            contents.NSRangeToByteRange(start: $0.location, length: $0.length)
        }

        let violationOffsets = declarationOffsets.filter { typeOffset in
            // find the last ACL token before the type
            guard let previousInternalByteRange = lastACLByteRange(before: typeOffset, in: allACLRanges) else {
                // didn't find a candidate token, so the ACL is implicit (not a violation)
                return false
            }

            // the ACL token correspond to the type if there're only
            // attributeBuiltin (`final` for example) tokens between them
            let length = typeOffset - previousInternalByteRange.location
            let range = ByteRange(location: previousInternalByteRange.location, length: length)
            return Set(file.syntaxMap.kinds(inByteRange: range)) == [.attributeBuiltin]
        }

        return violationOffsets.map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    private func lastACLByteRange(before typeOffset: ByteCount, in ranges: [ByteRange]) -> ByteRange? {
        let firstPartition = ranges.partitioned(by: { $0.location > typeOffset }).first
        return firstPartition.last
    }
}
