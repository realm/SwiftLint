//
//  ForceUnwrappingRule.swift
//  SwiftLint
//
//  Created by Benjamin Otto on 14/01/16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ForceUnwrappingRule: Rule, OptInRule {

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_unwrapping",
        name: "Force Unwrapping",
        description: "Force unwrapping should be avoided.",
        nonTriggeringExamples: [
            "if let url = NSURL(string: query)",
            "navigationController?.pushViewController(viewController, animated: true)"
        ],
        triggeringExamples: [
            "let url = NSURL(string: query)↓!",
            "navigationController↓!.pushViewController(viewController, animated: true)",
            "let unwrapped = optional↓!",
            "return cell↓!"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        // Get all identifiers from syntax map
        let identifiers = file.syntaxMap.tokens.filter({
                $0.type == SyntaxKind.Identifier.rawValue
            }).flatMap({
                file.contents.substringWithByteRange(start: $0.offset, length: $0.length)
            })
        // Check if there is any identifier followed by a '!'
        let violations = Set(identifiers).flatMap({
            return file.matchPattern("\($0)(\\((?:[^\\r\\n]|\\r(?!\\n))*?\\))?\\!")
        }).filter({ $0.1.first == .Identifier }).map({ $0.0 })

        return violations.map({
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: .Warning,
                location: Location(file: file, characterOffset: $0.location + $0.length - 1))
        })
    }
}
