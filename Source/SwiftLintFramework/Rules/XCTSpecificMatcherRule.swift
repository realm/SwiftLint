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
        nonTriggeringExamples: [
            // True/False
            "XCTAssertFalse(foo)",
            "XCTAssertTrue(foo)",
            // Nil/Not nil
            "XCTAssertNil(foo)",
            "XCTAssertNotNil(foo)",
            // Equal/Not equal
            "XCTAssertEqual(foo, 2)",
            "XCTAssertNotEqual(foo, \"false\")",
            // There's no need to touch commented out code
            "// XCTAssertEqual(foo, true)",
            "/* XCTAssertEqual(foo, true) */"
        ],
        triggeringExamples: [
            // Without message
            "↓XCTAssertEqual(foo, true)",
            "↓XCTAssertEqual(foo, false)",
            "↓XCTAssertEqual(foo, nil)",
            "↓XCTAssertNotEqual(foo, true)",
            "↓XCTAssertNotEqual(foo, false)",
            "↓XCTAssertNotEqual(foo, nil)",
            // Inverted logic (just in case...)
            "↓XCTAssertEqual(true, foo)",
            "↓XCTAssertEqual(false, foo)",
            "↓XCTAssertEqual(nil, foo)",
            "↓XCTAssertNotEqual(true, foo)",
            "↓XCTAssertNotEqual(false, foo)",
            "↓XCTAssertNotEqual(nil, foo)",
            // With message
            "↓XCTAssertEqual(foo, true, \"toto\")",
            "↓XCTAssertEqual(foo, false, \"toto\")",
            "↓XCTAssertEqual(foo, nil, \"toto\")",
            "↓XCTAssertNotEqual(foo, true, \"toto\")",
            "↓XCTAssertNotEqual(foo, false, \"toto\")",
            "↓XCTAssertNotEqual(foo, nil, \"toto\")",
            "↓XCTAssertEqual(true, foo, \"toto\")",
            "↓XCTAssertEqual(false, foo, \"toto\")",
            "↓XCTAssertEqual(nil, foo, \"toto\")",
            "↓XCTAssertNotEqual(true, foo, \"toto\")",
            "↓XCTAssertNotEqual(false, foo, \"toto\")",
            "↓XCTAssertNotEqual(nil, foo, \"toto\")"
        ],
        corrections: [
            // Without message
            "↓XCTAssertEqual(foo, true)": "XCTAssertTrue(foo)",
            "↓XCTAssertEqual(true, foo)": "XCTAssertTrue(foo)",
            "↓XCTAssertEqual(foo, false)": "XCTAssertFalse(foo)",
            "↓XCTAssertNotEqual(foo, true)": "XCTAssertFalse(foo)",
            "↓XCTAssertNotEqual(foo, false)": "XCTAssertTrue(foo)",
            "↓XCTAssertEqual(foo, nil)": "XCTAssertNil(foo)",
            "↓XCTAssertNotEqual(foo, nil)": "XCTAssertNotNil(foo)",
            // With message
            "↓XCTAssertEqual(foo, true, \"toto\")": "XCTAssertTrue(foo, \"toto\")",
            "↓XCTAssertEqual(true, foo, \"toto\")": "XCTAssertTrue(foo, \"toto\")",
            "↓XCTAssertEqual(foo, false, \"toto\")": "XCTAssertFalse(foo, \"toto\")",
            "↓XCTAssertNotEqual(foo, true, \"toto\")": "XCTAssertFalse(foo, \"toto\")",
            "↓XCTAssertNotEqual(foo, false, \"toto\")": "XCTAssertTrue(foo, \"toto\")",
            "↓XCTAssertEqual(foo, nil, \"toto\")": "XCTAssertNil(foo, \"toto\")",
            "↓XCTAssertNotEqual(foo, nil, \"toto\")": "XCTAssertNotNil(foo, \"toto\")",
            // There's no need to touch commented out code
            "// XCTAssertNotEqual(foo, nil)": "// XCTAssertNotEqual(foo, nil)",
            "/* XCTAssertNotEqual(foo, nil) */": "/* XCTAssertNotEqual(foo, nil) */"
        ]
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
        return file.correct(legacyRule: self, patterns: methodsMapping)
    }

    // MARK: - Private

    private func violationMatchesRanges(in file: File) -> [NSRange] {
        let methodsMappingKeys = methodsMapping.keys
        let methodNamesPattern = "(" + methodsMappingKeys.joined(separator: "|") + ")"
        let excludingKinds = SyntaxKind.commentKinds

        return file
            .match(pattern: methodNamesPattern)
            .filter { $1.filter(excludingKinds.contains).isEmpty && $1.first == .identifier }
            .map { $0.0 }
    }

    private let methodsMapping: [String: String] = [
        // Equal true
        "XCTAssertEqual\\(([^,]*), true": "XCTAssertTrue($1",
        "XCTAssertEqual\\(true, ([^,]*)": "XCTAssertTrue($1",
        // Equal false
        "XCTAssertEqual\\(([^,]*), false": "XCTAssertFalse($1",
        "XCTAssertEqual\\(false, ([^,]*)": "XCTAssertFalse($1",
        // Equal nil
        "XCTAssertEqual\\(([^,]*), nil": "XCTAssertNil($1",
        "XCTAssertEqual\\(nil, ([^,]*)": "XCTAssertNil($1",
        // Not equal true
        "XCTAssertNotEqual\\(([^,]*), true": "XCTAssertFalse($1",
        "XCTAssertNotEqual\\(true, ([^,]*)": "XCTAssertFalse($1",
        // Not equal false
        "XCTAssertNotEqual\\(([^,]*), false": "XCTAssertTrue($1",
        "XCTAssertNotEqual\\(false, ([^,]*)": "XCTAssertTrue($1",
        // Not equal Nil
        "XCTAssertNotEqual\\(([^,]*), nil": "XCTAssertNotNil($1",
        "XCTAssertNotEqual\\(nil, ([^,]*)": "XCTAssertNotNil($1"
    ]
}
