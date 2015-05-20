//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

protocol Validatable {
    var identifier: String { get }
    func validateFile(file: File) -> [StyleViolation]
}

protocol ParameterizedRule: Rule {
    typealias ParameterType
    var parameters: [RuleParameter<ParameterType>] { get }
}
