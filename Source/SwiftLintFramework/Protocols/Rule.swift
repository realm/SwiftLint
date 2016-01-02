//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol Rule {
    init() // Rules need to be able to be initialized with default values
    static var description: RuleDescription { get }
    func validateFile(file: File) -> [StyleViolation]
}

extension Rule {
    func isEqualTo(rule: Rule) -> Bool {
        return self.dynamicType.description == rule.dynamicType.description
    }
    // TODO: Add identifier extension
}

public protocol ParameterizedRule: Rule {
    typealias ParameterType: Equatable
    init(parameters: [RuleParameter<ParameterType>])
    var parameters: [RuleParameter<ParameterType>] { get }
}

public protocol ConfigurableRule: Rule {
    // TODO: Should switch this to AnyObject and failable
    init(config: [String: AnyObject])
    func isEqualTo(rule: ConfigurableRule) -> Bool
}

extension ParameterizedRule {
    func isEqualTo(rule: Self) -> Bool {
        return (self.dynamicType.description == rule.dynamicType.description) &&
               (self.parameters == rule.parameters)
    }
}

public protocol CorrectableRule: Rule {
    func correctFile(file: File) -> [Correction]
}

// MARK: - == Implementations

func == (lhs: [Rule], rhs: [Rule]) -> Bool {
    if lhs.count == rhs.count {
        return zip(lhs, rhs).map { $0.isEqualTo($1) }.reduce(true) { $0 && $1 }
    }

    return false
}
