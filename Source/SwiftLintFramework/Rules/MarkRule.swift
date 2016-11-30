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
            "// MARK: good",
            "// MARK: - good",
            "// MARK: -"
        ],
        triggeringExamples: [
            "//MARK: bad",
            "// MARK:bad",
            "//MARK:bad",
            "//  MARK: bad",
            "// MARK:  bad",
            "// MARK: -bad",
            "// MARK:- bad",
            "// MARK:-bad",
            "//MARK: - bad",
            "//MARK:- bad",
            "//MARK: -bad",
            "//MARK:-bad",
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let nonSpace = "[^ ]"
        let twoOrMoreSpace = " {2,}"
        let nonSpaceOrTwoOrMoreSpace = "(\(nonSpace)|\(twoOrMoreSpace))"
        let mark = "MARK:"
        let badSpaceStart = "(\(nonSpaceOrTwoOrMoreSpace)?\(mark)\(nonSpaceOrTwoOrMoreSpace))"
        let badSpaceEnd = "(\(nonSpaceOrTwoOrMoreSpace)\(mark)\(nonSpaceOrTwoOrMoreSpace)?)"
        let badSpaceAfterHyphen = "(\(mark) -([^ \\n]|\(twoOrMoreSpace)))"
        let pattern = [badSpaceStart, badSpaceEnd, badSpaceAfterHyphen].join(separator: "|")

        return file.matchPattern(pattern, withSyntaxKinds: [.comment]).flatMap { range in
            return StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }
}
