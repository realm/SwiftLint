//
//  SortedImportsRule.swift
//  SwiftLint
//
//  Created by Scott Berrevoets on 12/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct SortedImportsRule: ConfigurationProviderRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "sorted_imports",
        name: "Sorted Imports",
        description: "Imports should be sorted.",
        kind: .style,
        nonTriggeringExamples: [
            "import AAA\nimport BBB\nimport CCC\nimport DDD",
            "import Alamofire\nimport API",
            "import labc\nimport Ldef"
        ],
        triggeringExamples: [
            "import AAA\nimport ZZZ\nimport ↓BBB\nimport CCC"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let importRanges = file.match(pattern: "import\\s+\\w+", with: [.keyword, .identifier])
        let contents = file.contents.bridge()

        let importLength = 6
        let modulesAndOffsets: [(String, Int)] = importRanges.map { range in
            let moduleRange = NSRange(location: range.location + importLength,
                                      length: range.length - importLength)
            let moduleName = contents.substring(with: moduleRange)
                .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let offset = NSMaxRange(range) - moduleName.bridge().length
            return (moduleName, offset)
        }

        let modulePairs = zip(modulesAndOffsets, modulesAndOffsets.dropFirst())
        let violatingOffsets = modulePairs.flatMap { previous, current in
            return current < previous ? current.1 : nil
        }

        return violatingOffsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0))
        }
    }
}
