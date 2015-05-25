//
//  RuleExample.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 25/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation

public struct RuleExample {
    public let ruleName: String
    public let ruleDescription: String
    public let correctExamples: [String]
    public let failingExamples: [String]
    public let showExamples: Bool
    
    init(ruleName: String, ruleDescription: String, correctExamples: [String], failingExamples: [String], showExamples: Bool = true) {
        self.ruleName = ruleName
        self.ruleDescription = ruleDescription
        self.correctExamples = correctExamples
        self.failingExamples = failingExamples
        self.showExamples = showExamples
    }
}