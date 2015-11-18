//
//  TrailingClosureArgumentRule.swift
//  SwiftLint
//
//  Created by Keith Smiley on 8/20/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct MultilineClosureArgumentRule: Rule {
    public init() {}

    private static let regex = try! NSRegularExpression(pattern:
        "(^[^\\{\\n]*\\$0|\\$0[^\\}\\n]*$)", options: .AnchorsMatchLines)

    public func validateFile(file: File) -> [StyleViolation] {
        let range = NSRange(location: 0, length: file.contents.utf16.count)
        let matches = MultilineClosureArgumentRule.regex.matchesInString(file.contents,
            options: [], range: range)

        return matches.map { match in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: match.range.location))
        }
    }

    public static let description = RuleDescription(
        identifier: "closure_argument",
        name: "Multi-line closure argument",
        description: "Multi-line closures should not use $0",
        nonTriggeringExamples: [
            "foo.map { $0.toString() }\n",
            "foo.map { $0.something($1) }\n",
            "foo.map(self.something)\n",
            "foo.map{ foo in\nfoo.toString()\n}",
        ],
        triggeringExamples: [
            "foo.map {\n$0\n}",
            "$0",
            "foo($0).map { $0.toString() }",
        ]
    )
}
