//
//  Rule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public protocol OptInRule {}

public protocol Rule {
    init() // Rules need to be able to be initialized with default values
    static var description: RuleDescription { get }
    func validateFile(file: File) -> [StyleViolation]
}

extension Rule {
    func isEqualTo(rule: Rule) -> Bool {
        switch (self, rule) {
        case (let rule1 as ConfigurableRule, let rule2 as ConfigurableRule):
            return rule1.isEqualTo(rule2)
        default:
            return self.dynamicType.description == rule.dynamicType.description
        }
    }
}

public protocol ConfigurableRule: Rule {
    init?(config: AnyObject)
    func isEqualTo(rule: ConfigurableRule) -> Bool
}

public protocol ViolationLevelRule: ConfigurableRule {
    var warning: RuleParameter<Int> { get set }
    var error: RuleParameter<Int> { get set }
}

@available(*, deprecated=0.5.6, message="Use ConfigurableRule instead.")
public protocol ParameterizedRule: ConfigurableRule {
    typealias ParameterType: Equatable
    init(parameters: [RuleParameter<ParameterType>])
    var parameters: [RuleParameter<ParameterType>] { get }
}

// Default implementation for ConfigurableRule conformance
extension ParameterizedRule {
    public init?(config: AnyObject) {
        guard let array = [ParameterType].arrayOf(config) else {
            return nil
        }
        self.init(parameters: RuleParameter<ParameterType>.ruleParametersFromArray(array))
    }

    public func isEqualTo(rule: ConfigurableRule) -> Bool {
        if let rule = rule as? Self {
            return parameters == rule.parameters
        }
        return false
    }
}

public protocol CorrectableRule: Rule {
    func correctFile(file: File) -> [Correction]
}

// MARK: - ViolationLevelRule conformance to ConfigurableRule

public extension ViolationLevelRule {
    public init?(config: AnyObject) {
        self.init()
        if let config = [Int].arrayOf(config) where config.count > 0 {
            warning = RuleParameter(severity: .Warning, value: config[0])
            if config.count > 1 {
                error = RuleParameter(severity: .Error, value: config[1])
            }
        } else if let config = config as? [String: AnyObject] {
            if let warningNumber = config["warning"] as? Int {
                warning = RuleParameter(severity: .Warning, value: warningNumber)
            }
            if let errorNumber = config["error"] as? Int {
                error = RuleParameter(severity: .Error, value: errorNumber)
            }
        } else {
            return nil
        }
    }

    public func isEqualTo(rule: ConfigurableRule) -> Bool {
        if let rule = rule as? Self {
            return warning == rule.warning &&
                   error == rule.error
        }
        return false
    }
}

// MARK: - == Implementations

public func == (lhs: [Rule], rhs: [Rule]) -> Bool {
    if lhs.count == rhs.count {
        return zip(lhs, rhs).map { $0.isEqualTo($1) }.reduce(true) { $0 && $1 }
    }

    return false
}
