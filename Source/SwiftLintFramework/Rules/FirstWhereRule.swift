//
//  FirstWhereRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct FirstWhereRule: CallPairRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "first_where",
        name: "First Where",
        description: "Prefer using `.first(where:)` over `.filter { }.first` in collections.",
        kind: .performance,
        nonTriggeringExamples: [
            "kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier\n",
            "myList.first(where: { $0 % 2 == 0 })\n",
            "match(pattern: pattern).filter { $0.first == .identifier }\n",
            "(myList.filter { $0 == 1 }.suffix(2)).first\n"
        ],
        triggeringExamples: [
            "↓myList.filter { $0 % 2 == 0 }.first\n",
            "↓myList.filter({ $0 % 2 == 0 }).first\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first\n",
            "↓myList.map { $0 + 1 }.filter({ $0 % 2 == 0 }).first?.something()\n",
            "↓myList.filter(someFunction).first\n",
            "↓myList.filter({ $0 % 2 == 0 })\n.first\n",
            "(↓myList.filter { $0 == 1 }).first\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return validate(file: file,
                        pattern: "[\\}\\)]\\s*\\.first",
                        patternSyntaxKinds: [.identifier],
                        callNameSuffix: ".filter",
                        severity: configuration.severity)
    }

}
