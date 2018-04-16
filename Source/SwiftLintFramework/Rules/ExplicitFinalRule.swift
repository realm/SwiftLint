//
//  ExplicitFinalRule.swift
//  SwiftLint
//
//  Created by Andrew Harrison on 3/30/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitFinalRule: ASTRule, OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_final",
        name: "Explicit Final",
        description: "Non-open class types should always specify final to encourage composition over inheritance.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "final class A {}",
            "internal final class B {}",
            "private final class C {}",
            "public final class D {}",
            "open final class D {}",
            "open class D {}",
            "final class E {\n" +
            "    final class F { }\n" +
            "}",
            "final class G {\n" +
            "    final class H {\n" +
            "        final class I { }\n" +
            "    }\n" +
            "}",
            "enum J { }",
            "struct K { }",
            "protocol L { }"
        ],
        triggeringExamples: [
            "↓class A {}",
            "internal ↓class B {}",
            "private ↓class C {}",
            "public ↓class D {}",
            "final class E {\n" +
            "    ↓class F { }\n" +
            "}",
            "final class G {\n" +
            "    final class H {\n" +
            "        ↓class I { }\n" +
            "    }\n" +
            "}"
        ])

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .class,
              let accessibility = dictionary.accessibility,
              AccessControlLevel(identifier: accessibility) != .open,
              !dictionary.enclosedSwiftAttributes.contains("source.decl.attribute.final") else { return [] }

        guard let offset = dictionary.offset else { return [] }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
