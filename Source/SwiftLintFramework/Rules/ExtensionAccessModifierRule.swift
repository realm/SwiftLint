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
            "}"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .extension, let offset = dictionary.offset,
            dictionary.inheritedTypes.isEmpty else {
                return []
        }

        let declarations = dictionary.substructure.flatMap { entry -> AccessControlLevel? in
            guard entry.kind.flatMap(SwiftDeclarationKind.init) != nil else {
                return nil
            }

            return entry.accessibility.flatMap(AccessControlLevel.init(identifier:))
        }.unique

        guard declarations.count == 1, declarations != [.internal], declarations != [.private] else {
            return []
        }

        let syntaxTokens = file.syntaxMap.tokens
        let parts = syntaxTokens.partitioned { offset <= $0.offset }
        if let aclToken = parts.first.last, file.isACL(token: aclToken) {
            return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
