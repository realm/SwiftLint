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

    public init() {}

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

    public func validate(file: File) -> [StyleViolation] {
        let classes = testClasses(in: file)

        guard classes.count > 1 else { return [] }

        return classes.flatMap(toViolation(in: file, configuration: configuration, numberOfSpecs: classes.count))
    }

    // MARK: - Private

    private func testClasses(in file: File) -> [[String: SourceKitRepresentable]] {
        return file.structure.dictionary.substructure.filter {
            !$0.inheritedTypes.filter { testClasses().contains($0) }.isEmpty
        }
    }

    private func toViolation(in file: File,
                             configuration: SeverityConfiguration,
                             numberOfSpecs: Int) -> ([String: SourceKitRepresentable]) -> StyleViolation? {
        return { dictionary in
            guard let offset = dictionary.offset else { return nil }
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: "\(numberOfSpecs) test classes found in this file.")
        }
    }

    private func testClasses() -> [String] {
        return ["QuickSpec", "XCTestCase"]
    }
}
