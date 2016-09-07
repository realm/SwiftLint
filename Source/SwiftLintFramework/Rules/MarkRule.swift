//
//  MarkRule.swift
//  SwiftLint
//
//  Created by Krzysztof Rodak on 22/08/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct MarkRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "mark",
        name: "Mark",
        description: "MARK comment should be in valid format.",
        nonTriggeringExamples: [
            "// MARK: good\n",
            "// MARK: - good\n",
            "// MARK: -\n"
        ],
        triggeringExamples: [
            "//MARK: bad",
            "//MARK:bad",
            "// MARK: -bad",
            "// MARK:-bad",
            "//MARK:-bad"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let options = ["MARK:[^ ]", "[^ ]MARK: [^-]", "\\sMARK:[^ ]", "MARK:[ ][-][^\\s ]"]
        let pattern = "(" + options.joinWithSeparator("|") + ")"

        return file.matchPattern(pattern, withSyntaxKinds: [.Comment]).flatMap { range in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }
}
