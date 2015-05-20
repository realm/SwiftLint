//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol Validatable {
    func validateFile(file: File) -> [StyleViolation]
    var example: RuleExample? { get }
}

protocol Rule: Validatable {
    typealias ParameterType

    var identifier: String { get }
    var parameters: [RuleParameter<ParameterType>] { get }

}
