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
        let varName = RegexHelpers.varNameGroup
        let trueVar = RegexHelpers.trueVariable
        let falseVar = RegexHelpers.falseVariable
        let nilVar = RegexHelpers.nilVariable

        return [
            // Equal true
            "XCTAssertEqual\\(\(varName),\(trueVar)": "XCTAssertTrue($1",
            "XCTAssertEqual\\(\(trueVar),\(varName)": "XCTAssertTrue($1",
            // Equal false
            "XCTAssertEqual\\(\(varName),\(falseVar)": "XCTAssertFalse($1",
            "XCTAssertEqual\\(\(falseVar),\(varName)": "XCTAssertFalse($1",
            // Equal nil
            "XCTAssertEqual\\(\(varName),\(nilVar)": "XCTAssertNil($1",
            "XCTAssertEqual\\(\(nilVar),\(varName)": "XCTAssertNil($1",
            // Not equal true
            "XCTAssertNotEqual\\(\(varName),\(trueVar)": "XCTAssertFalse($1",
            "XCTAssertNotEqual\\(\(trueVar),\(varName)": "XCTAssertFalse($1",
            // Not equal false
            "XCTAssertNotEqual\\(\(varName),\(falseVar)": "XCTAssertTrue($1",
            "XCTAssertNotEqual\\(\(falseVar),\(varName)": "XCTAssertTrue($1",
            // Not equal Nil
            "XCTAssertNotEqual\\(\(varName),\(nilVar)": "XCTAssertNotNil($1",
            "XCTAssertNotEqual\\(\(nilVar),\(varName)": "XCTAssertNotNil($1"
        ]
    }
}
