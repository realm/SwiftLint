//
//  RuleExample.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 25/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public struct RuleExample {
    public let ruleName: String
    public let ruleDescription: String
    public let nonTriggeringExamples: [String]
    public let triggeringExamples: [String]
    public let showExamples: Bool

    public init(ruleName: String,
                ruleDescription: String,
                nonTriggeringExamples: [String],
                triggeringExamples: [String],
                showExamples: Bool = true) {
        self.ruleName = ruleName
        self.ruleDescription = ruleDescription
        self.nonTriggeringExamples = nonTriggeringExamples
        self.triggeringExamples = triggeringExamples
        self.showExamples = showExamples
    }
}
