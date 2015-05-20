//
//  ASTRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

protocol ASTRule: Rule {
    func validateFile(file: File, dictionary: XPCDictionary) -> [StyleViolation]

    func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation]
}

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