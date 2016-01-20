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

public protocol ConfigurationProviderRule: ConfigurableRule {
    typealias ConfigurationType: RuleConfiguration
    var configuration: ConfigurationType { get set }
}

public protocol ViolationLevelRule: ConfigurableRule {
    var warning: RuleParameter<Int> { get set }
    var error: RuleParameter<Int> { get set }
}

public protocol CorrectableRule: Rule {
    func correctFile(file: File) -> [Correction]
}

// MARK: - ConfigurationProviderRule conformance to Configurable

public extension ConfigurationProviderRule {
    public init?(config: AnyObject) {
        self.init()
        if let config = ConfigurationType(config: config) {
            configuration = config
        } else {
            return nil
        }
    }

    public func isEqualTo(rule: ConfigurableRule) -> Bool {
        if let rule = rule as? Self {
            return configuration.isEqualTo(rule.configuration)
        }
        return false
    }
}

// MARK: - ViolationLevelRule conformance to ConfigurableRule

public extension ViolationLevelRule {
    public init?(config: AnyObject) {
        self.init()
        if let config = [Int].arrayOf(config) where !config.isEmpty {
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
