//
//  ExplicitTypeInterfaceRule.swift
//  SwiftLint
//
//  Created by Kim de Vos on 02/28/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitTypeInterfaceRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_type_interface",
        name: "Explicit Type Interface",
        description: "Properties should have a type interface",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "class Foo {\n  var myVar: Int? = 0\n}\n",
            "class Foo {\n  let myVar: Int? = 0\n}\n",
            "class Foo {\n  static var myVar: Int? = 0\n}\n",
            "class Foo {\n  class var myVar: Int? = 0\n}\n"
        ],
        triggeringExamples: [
            "class Foo {\n  ↓var myVar = 0\n\n}\n",
            "class Foo {\n  ↓let mylet = 0\n\n}\n",
            "class Foo {\n  ↓static var myStaticVar = 0\n}\n",
            "class Foo {\n  ↓class var myClassVar = 0\n}\n"
        ]
    )

    private static let allowedKinds: Set<SwiftDeclarationKind> = [.varInstance, .varLocal,
                                                                  .varStatic, .varClass]

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        guard ExplicitTypeInterfaceRule.allowedKinds.contains(kind),
            !containsType(dictionary: dictionary),
            let offset = dictionary.offset else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    private func containsType(dictionary: [String: SourceKitRepresentable]) -> Bool {
        return dictionary.typeName != nil
    }
}
