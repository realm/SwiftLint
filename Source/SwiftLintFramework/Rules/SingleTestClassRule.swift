//
//  SingleTestClassRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/15/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SingleTestClassRule: Rule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "single_test_class",
        name: "Single Test Class",
        description: "Test files should contain a single QuickSpec or XCTestCase class.",
        kind: .style,
        nonTriggeringExamples: [
            "class FooTests {  }\n",
            "class FooTests: QuickSpec {  }\n",
            "class FooTests: XCTestCase {  }\n"
        ],
        triggeringExamples: [
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: QuickSpec {  }\n",
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: QuickSpec {  }\n↓class TotoTests: QuickSpec {  }\n",
            "↓class FooTests: XCTestCase {  }\n↓class BarTests: XCTestCase {  }\n",
            "↓class FooTests: XCTestCase {  }\n↓class BarTests: XCTestCase {  }\n↓class TotoTests: XCTestCase {  }\n",
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: XCTestCase {  }\n",
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: XCTestCase {  }\nclass TotoTests {  }\n"
        ]
    )

    private let testClasses = ["QuickSpec", "XCTestCase"]

    public init() {}

    public func validate(file: File) -> [StyleViolation] {
        let classes = testClasses(in: file)

        guard classes.count > 1 else { return [] }

        return classes.flatMap { dictionary in
            guard let offset = dictionary.offset else { return nil }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: "\(classes.count) test classes found in this file.")
        }
    }

    private func testClasses(in file: File) -> [[String: SourceKitRepresentable]] {
        return file.structure.dictionary.substructure.filter { dictionary in
            guard
                let kind = dictionary.kind,
                SwiftDeclarationKind(rawValue: kind) == .class
                else { return false }

            return !dictionary.inheritedTypes.filter { testClasses.contains($0) }.isEmpty
        }
    }
}
