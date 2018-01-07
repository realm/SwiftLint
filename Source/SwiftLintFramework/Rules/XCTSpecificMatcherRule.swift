//
//  XCTSpecificMatcher.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/6/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct XCTSpecificMatcherRule: OptInRule, ConfigurationProviderRule, CorrectableRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "xct_specific_matcher",
        name: "XCTest Specific Matcher",
        description: "Prefer specific XCTest matchers over `XCTAssertEqual` and `XCTAssertNotEqual`",
        kind: .idiomatic,
        nonTriggeringExamples: XCTSpecificMatcherRuleExamples.nonTriggeringExamples,
        triggeringExamples: XCTSpecificMatcherRuleExamples.triggeringExamples,
        corrections: XCTSpecificMatcherRuleExamples.corrections
    )

    public func validate(file: File) -> [StyleViolation] {
        let matches = violationMatchesRanges(in: file)

        return matches.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        return file.correct(legacyRule: self, patterns: methodsMapping())
    }

    // MARK: - Private

    private func violationMatchesRanges(in file: File) -> [NSRange] {
        let methodsMappingKeys = methodsMapping().keys
        let methodNamesPattern = "(" + methodsMappingKeys.joined(separator: "|") + ")"
        let excludingKinds = SyntaxKind.commentKinds

        return file
            .match(pattern: methodNamesPattern)
            .filter { $1.filter(excludingKinds.contains).isEmpty && $1.first == .identifier }
            .map { $0.0 }
    }

    private func methodsMapping() -> [String: String] {
        let varName = "\\s*(.*?)\\s*"
        let trueParam = "\\s*true\\s*"
        let falseParam = "\\s*false\\s*"
        let nilParam = "\\s*nil\\s*"

        return [
            // Equal true
            "XCTAssertEqual\\(\(varName),\(trueParam)\\)": "XCTAssertTrue($1)",
            "XCTAssertEqual\\(\(trueParam),\(varName)\\)": "XCTAssertTrue($1)",
            // Equal false
            "XCTAssertEqual\\(\(varName),\(falseParam)\\)": "XCTAssertFalse($1)",
            "XCTAssertEqual\\(\(falseParam),\(varName)\\)": "XCTAssertFalse($1)",
            // Equal nil
            "XCTAssertEqual\\(\(varName),\(nilParam)\\)": "XCTAssertNil($1)",
            "XCTAssertEqual\\(\(nilParam),\(varName)\\)": "XCTAssertNil($1)",
            // Not equal true
            "XCTAssertNotEqual\\(\(varName),\(trueParam)\\)": "XCTAssertFalse($1)",
            "XCTAssertNotEqual\\(\(trueParam),\(varName)\\)": "XCTAssertFalse($1)",
            // Not equal false
            "XCTAssertNotEqual\\(\(varName),\(falseParam)\\)": "XCTAssertTrue($1)",
            "XCTAssertNotEqual\\(\(falseParam),\(varName)\\)": "XCTAssertTrue($1)",
            // Not equal Nil
            "XCTAssertNotEqual\\(\(varName),\(nilParam)\\)": "XCTAssertNotNil($1)",
            "XCTAssertNotEqual\\(\(nilParam),\(varName)\\)": "XCTAssertNotNil($1)"
        ]
    }
}
