//
//  ExtensionAccessModifierRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 26/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExtensionAccessModifierRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "extension_access_modifier",
        name: "Extension Access Modifier",
        description: "Prefer to use extension access modifiers",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "extension Foo: SomeProtocol {\n" +
            "   public var bar: Int { return 1 }\n" +
            "}",
            "extension Foo {\n" +
            "   private var bar: Int { return 1 }\n" +
            "   public var baz: Int { return 1 }\n" +
            "}",
            "extension Foo {\n" +
            "   private var bar: Int { return 1 }\n" +
            "   public func baz() {}\n" +
            "}",
            "extension Foo {\n" +
            "   var bar: Int { return 1 }\n" +
            "   var baz: Int { return 1 }\n" +
            "}",
            "public extension Foo {\n" +
            "   var bar: Int { return 1 }\n" +
            "   var baz: Int { return 1 }\n" +
            "}",
            "extension Foo {\n" +
            "   private bar: Int { return 1 }\n" +
            "   private baz: Int { return 1 }\n" +
            "}",
            "extension Foo {\n" +
            "   open bar: Int { return 1 }\n" +
            "   open baz: Int { return 1 }\n" +
            "}"
        ],
        triggeringExamples: [
            "↓extension Foo {\n" +
            "   public var bar: Int { return 1 }\n" +
            "   public var baz: Int { return 1 }\n" +
            "}",
            "↓extension Foo {\n" +
            "   public var bar: Int { return 1 }\n" +
            "   public func baz() {}\n" +
            "}",
            "public extension Foo {\n" +
            "   public ↓func bar() {}\n" +
            "   public ↓func baz() {}\n" +
            "}"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .extension, let offset = dictionary.offset,
            dictionary.inheritedTypes.isEmpty else {
                return []
        }

        let declarations = dictionary.substructure.flatMap { entry -> (acl: AccessControlLevel, offset: Int)? in
            guard entry.kind.flatMap(SwiftDeclarationKind.init) != nil,
                let acl = entry.accessibility.flatMap(AccessControlLevel.init(identifier:)),
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

    private func declarationsViolations(file: File, acl: AccessControlLevel,
                                        declarationOffsets: [Int],
                                        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard let offset = dictionary.offset, let length = dictionary.length,
            case let contents = file.contents.bridge(),
            let range = contents.byteRangeToNSRange(start: offset, length: length) else {
                return []
        }

        // find all ACL tokens
        let allACLRanges = file.match(pattern: acl.description, with: [.attributeBuiltin], range: range).flatMap {
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
