//
//  Region.swift
//  SwiftLint
//
//  Created by JP Simard on 8/29/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct Region: Equatable {
    public let start: Location
    public let end: Location
    public let disabledRuleIdentifiers: Set<RuleIdentifier>

    public init(start: Location, end: Location, disabledRules: Set<RuleIdentifier>) {
        self.start = start
        self.end = end
        self.disabledRuleIdentifiers = disabledRules
    }

    public func contains(_ location: Location) -> Bool {
        return start <= location && end >= location
    }

    public func isRuleEnabled(_ rule: Rule) -> Bool {
        return !isRuleDisabled(rule)
    }

    public func isRuleDisabled(_ rule: Rule) -> Bool {
        let identifiers = type(of: rule).description.allIdentifiers
        return disabledRuleIdentifiers.contains(.all) ||
            identifiers.reduce(false) { $0 || disabledRuleIdentifiers.contains(RuleIdentifier($1)) }
    }

    public func deprecatedAliasesDisabling(rule: Rule) -> Set<String> {
        let identifiers = type(of: rule).description.deprecatedAliases
        return Set(disabledRuleIdentifiers.map { $0.stringRepresentation }).intersection(identifiers)
    }
}

// MARK: Equatable
public func == (lhs: Region, rhs: Region) -> Bool {
    return lhs.start == rhs.start &&
        lhs.end == rhs.end &&
        lhs.disabledRuleIdentifiers == rhs.disabledRuleIdentifiers
}
