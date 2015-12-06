//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol Rule {
    static var description: RuleDescription { get }
    func validateFile(file: File) -> [StyleViolation]
}

public protocol ParameterizedRule: Rule {
    typealias ParameterType
    init(parameters: [RuleParameter<ParameterType>])
    var parameters: [RuleParameter<ParameterType>] { get }
}

public protocol CorrectableRule: Rule {
    func correctFile(file: File) -> [Correction]
}
