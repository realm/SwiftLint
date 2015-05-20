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
    public let showExamples: Bool = true
}