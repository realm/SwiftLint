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
    init(configuration: AnyObject) throws
    static var description: RuleDescription { get }
    func validateFile(file: File) -> [StyleViolation]
    func isEqualTo(rule: Rule) -> Bool
    var configurationDescription: String { get }
}

extension Rule {
    public func isEqualTo(rule: Rule) -> Bool {
        return self.dynamicType.description == rule.dynamicType.description
    }
}

public protocol OptInRule: Rule {}

public protocol ConfigurationProviderRule: Rule {
    associatedtype ConfigurationType: RuleConfiguration
    var configuration: ConfigurationType { get set }
}

public protocol CorrectableRule: Rule {
    func correctFile(file: File) -> [Correction]
}

public protocol SourceKitFreeRule: Rule {}

// MARK: - ConfigurationProviderRule conformance to Configurable

public extension ConfigurationProviderRule {
    public init(configuration: AnyObject) throws {
        self.init()
        try self.configuration.applyConfiguration(configuration)
    }

    public func isEqualTo(rule: Rule) -> Bool {
        if let rule = rule as? Self {
            return configuration.isEqualTo(rule.configuration)
        }
        return false
    }

    public var configurationDescription: String {
        return configuration.consoleDescription
    }
}

// MARK: - == Implementations

public func == (lhs: [Rule], rhs: [Rule]) -> Bool {
    if lhs.count == rhs.count {
        return zip(lhs, rhs).map { $0.isEqualTo($1) }.reduce(true) { $0 && $1 }
    }

    return false
}
