//
//  ForceUnwrappingRule.swift
//  SwiftLint
//
//  Created by Benjamin Otto on 14/01/16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ForceUnwrappingRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_unwrapping",
        name: "Force Unwrapping",
        description: "Force unwrapping should be avoided.",
        nonTriggeringExamples: [
            "if let url = NSURL(string: query)",
            "navigationController?.pushViewController(viewController, animated: true)",
            "let s as! Test",
            "try! canThrowErrors()",
            "let object: AnyObject!",
        ],
        triggeringExamples: [
            "let url = NSURL(string: query)↓!",
            "navigationController↓!.pushViewController(viewController, animated: true)",
            "let unwrapped = optional↓!",
            "return cell↓!",
            "let url = NSURL(string: \"http://www.google.com\")↓!"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("\\S!",
            excludingSyntaxKinds: SyntaxKind.commentKeywordStringAndTypeidentifierKinds()).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: NSMaxRange($0) - 1))
        }
    }
}
