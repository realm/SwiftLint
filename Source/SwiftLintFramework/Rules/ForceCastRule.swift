//
//  ForceCastRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ForceCastRule: Rule {
    public init() { }

    let identifier = "force_cast"
    let parameters = [RuleParameter<Void>]()

    public func validateFile(file: File) -> [StyleViolation] {
        return file.matchPattern("as!", withSyntaxKinds: [.Keyword]).map { range in
            return StyleViolation(type: .ForceCast,
                location: Location(file: file, offset: range.location),
                severity: .High,
                reason: "Force casts should be avoided")
        }
    }

    public let example: RuleExample = RuleExample(
        ruleName: "Force Cast Rule",
        ruleDescription: "This rule checks whether you don't do force casts.",
        correctExamples: [
            "NSNumber() as? Int\n",
            "// NSNumber() as! Int\n",
        ],
        failingExamples: [ "NSNumber() as! Int\n" ]
    )

}
