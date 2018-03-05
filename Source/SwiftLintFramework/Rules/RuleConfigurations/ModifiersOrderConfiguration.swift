//
//  ModifiersOrderConfiguration.swift
//  SwiftLint
//
//  Created by Jose Cheyo Jimenez on 06/04/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct ModifiersOrderConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var beforeACL = [String]()
    private(set) var afterACL = [String]()

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", before_acl: \(beforeACL)" +
            ", after_acl: \(afterACL)"
    }

    public init(beforeACL: [String] = [],
                afterACL: [String] = []) {
        self.beforeACL = beforeACL
        self.afterACL = afterACL
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let beforeACL = configuration["before_acl"] as? [String] {
            self.beforeACL = beforeACL
        }

        if let afterACL = configuration["after_acl"] as? [String] {
            self.afterACL = afterACL
        }

        // Make sure no entries are in both sets
        if !Set(afterACL).isDisjoint(with: beforeACL) {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}

public func == (lhs: ModifiersOrderConfiguration,
                rhs: ModifiersOrderConfiguration) -> Bool {
    return lhs.severityConfiguration == rhs.severityConfiguration &&
        lhs.beforeACL == rhs.beforeACL &&
        rhs.afterACL == rhs.afterACL
}
