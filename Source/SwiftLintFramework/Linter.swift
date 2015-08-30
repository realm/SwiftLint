//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SwiftXPC
import SourceKittenFramework

public struct Linter {
    private let file: File

    private let rules: [Rule]

    public var styleViolations: [StyleViolation] {
        let regions = file.regions()
        return rules.flatMap { rule in
            return rule.validateFile(self.file).filter { styleViolation in
                guard let violationRegion = regions.filter({
                    $0.start <= styleViolation.location && $0.end >= styleViolation.location
                }).first else {
                    return true
                }
                return !violationRegion.disabledRuleIdentifiers.contains(rule.identifier)
            }
        }
    }

    public var ruleExamples: [RuleExample] {
        return rules.flatMap { $0.example }
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File, configuration: Configuration = Configuration()!) {
        self.file = file
        rules = configuration.rules
    }
}
