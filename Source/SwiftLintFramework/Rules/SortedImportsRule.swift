//
//  SortedImportsRule.swift
//  SwiftLint
//
//  Created by Scott Berrevoets on 12/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct SortedImportsRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    private let moduleCharacterOffset = "import ".characters.count

    public init() {}

    public static let description = RuleDescription(
        identifier: "sorted_imports",
        name: "Sorted Imports",
        description: "Imports should be sorted.",
        nonTriggeringExamples: [
            "import AAA\nimport BBB\nimport CCC\nimport DDD"
        ],
        triggeringExamples: [
            "import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let pattern = "import\\s+\\w+"

        var previousMatch = ""
        return file.matchPattern(pattern).flatMap { range, kinds in
            if kinds.count != 2 || kinds[0] != .keyword || kinds[1] != .identifier {
                return nil
            }

            let match = file.contents.bridge().substring(with: range)
            defer { previousMatch = match }

            if match > previousMatch {
                return nil
            }

            let characterOffset = range.location + moduleCharacterOffset
            let location = Location(file: file, characterOffset: characterOffset)
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity, location: location)

        }
    }
}
