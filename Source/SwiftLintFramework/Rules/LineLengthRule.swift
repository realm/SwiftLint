//
//  LineLengthRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct LineLengthRule: ConfigProviderRule {
    public var config = SeverityLevelConfig(warning: 100, error: 200)

    public init() {}

    public static let description = RuleDescription(
        identifier: "line_length",
        name: "Line Length",
        description: "Lines should not span too many characters."
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return file.lines.flatMap { line in
            let length = line.content.characters.count
            for param in config.params where length > param.value {
                return StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: param.severity,
                    location: Location(file: file.path, line: line.index),
                    reason: "Line should be \(config.warning) characters or less: " +
                    "currently \(length) characters")
            }
            return nil
        }
    }
}
