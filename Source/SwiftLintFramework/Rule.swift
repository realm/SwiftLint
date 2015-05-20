//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

protocol Rule {
    typealias ParameterType

    var identifier: String { get }
    var parameters: [RuleParameter<ParameterType>] { get }

    func validateFile(file: File) -> [StyleViolation]
}
