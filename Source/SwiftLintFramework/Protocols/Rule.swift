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
        // TODO: Is there a better way to do this?
        switch (self, rule) {
        case (let rule1 as ConfigurableRule, let rule2 as ConfigurableRule):
            return rule1.isEqualTo(rule2)
        default:
            return self.dynamicType.description == rule.dynamicType.description
        }
    }
}

public protocol ParameterizedRule: Rule {
    typealias ParameterType: Equatable
    init(parameters: [RuleParameter<ParameterType>])
    var parameters: [RuleParameter<ParameterType>] { get }
}

public protocol ConfigurableRule: Rule {
    init?(config: AnyObject)
    func isEqualTo(rule: ConfigurableRule) -> Bool
}

extension ParameterizedRule {
    func isEqualTo(rule: Self) -> Bool {
        return (self.dynamicType.description == rule.dynamicType.description) &&
               (self.parameters == rule.parameters)
    }
}

extension ParameterizedRule where Self: ConfigurableRule, ParameterType == Int {

    public init?(config: AnyObject) {
        if let array = Self.arrayOfInts(config) {
            self.init(parameters: RuleParameter<Int>.ruleParametersFromArray(array))
        } else {
            return nil
        }
    }

    static func arrayOfInts(obj: AnyObject?) -> [Int]? {
        if let array = obj as? [Int] {
            return array
        } else if let number = obj as? Int {
            return [number]
        }
        return nil
    }

    public func isEqualTo(rule: ConfigurableRule) -> Bool {
        if let rule = rule as? Self {
            return self.parameters == rule.parameters
        }
        return false
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
