//
//  StrictFilePrivateRule.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 05/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct StrictFilePrivateRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "strict_fileprivate",
        name: "Strict fileprivate",
        description: "`fileprivate` should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "extension String {}",
            "private extension String {}",
            "public \n extension String {}",
            "open extension \n String {}",
            "internal extension String {}"
        ],
        triggeringExamples: [
            "↓fileprivate extension String {}",
            "↓fileprivate \n extension String {}",
            "↓fileprivate extension \n String {}",
            "extension String {\n↓fileprivate func Something(){}\n}",
            "class MyClass {\n↓fileprivate let myInt = 4\n}",
            "class MyClass {\n↓fileprivate(set) var myInt = 4\n}",
            "struct Outter {\nstruct Inter {\n↓fileprivate struct Inner {}\n}\n}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        // Mark all fileprivate occurences as a violation
        return file.match(pattern: "fileprivate", with: [.attributeBuiltin]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
