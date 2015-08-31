//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol Rule {
    var identifier: String { get }
    static var name: String { get }
    func validateFile(file: File) -> [StyleViolation]
    var example: RuleExample { get }
}

public protocol ParameterizedRule: Rule {
    typealias ParameterType
    var parameters: [RuleParameter<ParameterType>] { get }
}

public let allRules: [Rule] = [
    LineLengthRule(),
    LeadingWhitespaceRule(),
    TrailingWhitespaceRule(),
    ReturnArrowWhitespaceRule(),
    TrailingNewlineRule(),
    OperatorFunctionWhitespaceRule(),
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
