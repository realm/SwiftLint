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

private func flatten<A>(x: [A?]) -> [A] {
    return x.reduce([]) { (var arr, optionalElement) in
        if let el = optionalElement {
            arr.append(el)
        }
        return arr
    }
}

public struct Linter {
    private let file: File

    private let rules: [Validatable] = [
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
        NestingRule()
    ]

    public var styleViolations: [StyleViolation] {
        return reduce(rules.map { $0.validateFile(self.file) }, [], +)
    }

    public var explainableRules: [RuleExample] {
        return flatten(rules.map { $0.example })
    }

    /**
    Initialize a Linter by passing in a File.

    :param: file File to lint.
    */
    public init(file: File) {
        self.file = file
    }
}
