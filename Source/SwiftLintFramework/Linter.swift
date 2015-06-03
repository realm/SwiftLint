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
        return rules.flatMap {
            if !(file.contents as NSString).containsString("// SwiftLint ignore \($0.identifier)")
                && !(file.contents as NSString).containsString("// SwiftLint ignore all") {
                return $0.validateFile(file)
            } else {
                return []
            }
        }
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
