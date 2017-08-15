//
//  QuickSpecLimitRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/15/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct QuickSingleSpecRule: Rule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "quick_single_spec",
        name: "Quick Single Spec",
        description: "Test files should contain a single QuickSpec class.",
        kind: .style,
        nonTriggeringExamples: [
            "class FooTests {  }\n",
            "class FooTests: QuickSpec {  }\n"
        ],
        triggeringExamples: [
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: QuickSpec {  }\n",
            "↓class FooTests: QuickSpec {  }\n↓class BarTests: QuickSpec {  }\n↓class TotoTests: QuickSpec {  }\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let specs = quickSpecs(in: file)

        guard specs.count > 1 else { return [] }

        return specs.flatMap(toViolation(in: file, configuration: configuration, numberOfSpecs: specs.count))
    }

    // MARK: - Private

    private func quickSpecs(in file: File) -> [[String: SourceKitRepresentable]] {
        return file.structure.dictionary.substructure.filter { $0.inheritedTypes.contains("QuickSpec") }
    }

    private func toViolation(in file: File,
                             configuration: SeverityConfiguration,
                             numberOfSpecs: Int) -> ([String: SourceKitRepresentable]) -> StyleViolation? {
        return { dictionary in
            guard let offset = dictionary.offset else { return nil }
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, byteOffset: offset),
                                  reason: "\(numberOfSpecs) Quick Specs found in this file.")
        }
    }
}
