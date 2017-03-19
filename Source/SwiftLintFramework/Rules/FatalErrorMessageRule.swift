//
//  FatalErrorMessageRule.swift
//  SwiftLint
//
//  Created by Kim de Vos on 03/18/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct FatalErrorMessageRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "fatal_error_message",
        name: "Fatal Errror Message",
        description: "The fatalError should have a message",
        nonTriggeringExamples: [
            "func foo() {\n  fatalError(\"Foo\")\n}\n"
        ],
        triggeringExamples: [
            "func foo() {\n  ↓fatalError(\"\")\n}\n",
            "func foo() {\n  ↓fatalError()\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard SwiftDeclarationKind.functionKinds().contains(kind)
        else {
            return []
        }

        return dictionary.substructure.flatMap { subDict -> [StyleViolation] in
            var violations = validate(file: file, dictionary: subDict)

            if let offset = subDict.offset,
                let kindString = subDict.kind,
                let kind = SwiftExpressionKind(rawValue: kindString),
                kind == SwiftExpressionKind.call,
                subDict.name == "fatalError",
                subDict.bodyLength == 2 || subDict.bodyLength == 0 {
                let violation = StyleViolation(ruleDescription: type(of: self).description,
                                               severity: configuration.severity,
                                               location: Location(file: file, byteOffset: offset))

                violations.append(violation)
            }

            return violations
        }
    }
}
