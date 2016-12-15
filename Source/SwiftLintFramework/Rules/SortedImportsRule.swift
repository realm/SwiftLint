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

    public init() {}

    public static let description = RuleDescription(
        identifier: "sorted_imports",
        name: "Sorted Imports",
        description: "Imports should be sorted.",
        nonTriggeringExamples: [
            "import AAA\nimport BBB\nimport CCC\nimport DDD"
        ],
        triggeringExamples: [
            "import AAA\nimport ZZZ\nimport BBB\nimport CCC",
            "import AAA\nimport ZZZ\nimport BBB\nimport CCC\nimport AAA"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let pattern = "import\\s+(\\w+)"
        let excludingKinds = SyntaxKind.commentAndStringKinds()

        let importRanges = file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds)
        let imports = importRanges.map { file.contents.substring($0.location, length: $0.length) }

        var violations = [StyleViolation]()
        for index in 0 ..< imports.count {
            if index == 0 || imports[index] > imports[index - 1] {
                continue
            }

            let location = Location(file: file, characterOffset: importRanges[index].location)
            violations.append(
                              StyleViolation(ruleDescription: type(of: self).description,
                                             severity: configuration.severity, location: location)
                             )
        }

        return violations
    }
}
