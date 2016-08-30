//
//  ExplicitInitRule.swift
//  SwiftLint
//
//  Created by Matt Taube on 7/2/16.
//  Copyright (c) 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitInitRule: ConfigurationProviderRule, CorrectableRule, OptInRule {

    private let pattern = "\\b([A-Z][A-Za-z]*)\\.init\\("

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "explicit_init",
        name: "Explicit Init",
        description: "Explicitly calling .init() should be avoided.",
        nonTriggeringExamples: [
            "self.init(",
            "self.init",
            "Abc.init",
            "abc.init(",
            "$0.init("
        ],
        triggeringExamples: [
            "Abc.init(",
            "Abc(NSURL.init(someString"
        ],
        corrections: [
            "Abc.init(": "Abc(",
            "Abc(NSURL.init(someString": "Abc(NSURL(someString"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return violationRangesInFile(file).flatMap { range in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }

    private func violationRangesInFile(file: File) -> [NSRange] {
        let excludingKinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds)
    }

    public func correctFile(file: File) -> [Correction] {
        let matches = violationRangesInFile(file)
        guard !matches.isEmpty else { return [] }

        let regularExpression = regex(pattern)
        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents
        for range in matches.reverse() {
            contents = regularExpression.stringByReplacingMatchesInString(contents,
                                                                          options: [],
                                                                          range: range,
                                                                          withTemplate: "$1(")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}
