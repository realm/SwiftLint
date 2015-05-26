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

    private let rules: [Rule] = [
        LineLengthRule(),
        LeadingWhitespaceRule(),
        TrailingWhitespaceRule(),
        TrailingNewlineRule(),
        ForceCastRule(),
        FileLengthRule(),
        TodoRule(),
        ColonRule(),
        TypeNameRule(),
        VariableNameRule(),
        TypeBodyLengthRule(),
        FunctionBodyLengthRule(),
        NestingRule(),
        ControlStatementRule()
    ]

    public var styleViolations: [StyleViolation] {
        return rules.flatMap { $0.validateFile(file) }
    }

    public var ruleExamples: [RuleExample] {
        return compact(rules.map { $0.example })
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.file = file
    }
}
