//
//  MissingDocsRuleConfiguration.swift
//  SwiftLint
//
//  Created by Steffen Kötte on 04/26/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation

public struct MissingDocsRuleConfiguration: RuleConfiguration {

    private(set) var parameters = [RuleParameter<AccessControlLevel>]()

    public var consoleDescription: String {
        return parameters.group { $0.severity }.map {
            "\($0.rawValue): \($1.map { $0.value.description }.joined(separator: ", "))"
        }.joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard let dict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        let parameters = try dict.flatMap { (key: String, value: Any) -> [RuleParameter<AccessControlLevel>] in
            guard let severity = ViolationSeverity(rawValue: key) else {
                throw ConfigurationError.unknownConfiguration
            }
            if let array = [String].array(of: value) {
                return try array.map {
                    guard let acl = AccessControlLevel(description: $0) else {
                        throw ConfigurationError.unknownConfiguration
                    }
                    return RuleParameter<AccessControlLevel>(severity: severity, value: acl)
                }
            } else if let string = value as? String, let acl = AccessControlLevel(description: string) {
                return [RuleParameter<AccessControlLevel>(severity: severity, value: acl)]
            }
            throw ConfigurationError.unknownConfiguration
        }
        guard parameters.count == parameters.map({ $0.value }).unique.count else {
            throw ConfigurationError.unknownConfiguration
        }
        self.parameters = parameters
    }

    public func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool {
        guard let config = ruleConfiguration as? MissingDocsRuleConfiguration else {
            return false
        }
        return parameters == config.parameters
    }

}
