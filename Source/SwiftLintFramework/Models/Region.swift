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
    let start: Location
    let end: Location
    let disabledRuleIdentifiers: Set<String>

    public init(start: Location, end: Location, disabledRuleIdentifiers: Set<String>) {
        self.start = start
        self.end = end
        self.disabledRuleIdentifiers = disabledRuleIdentifiers
    }

    public func contains(_ location: Location) -> Bool {
        return start <= location && end >= location
    }

    public func isRuleEnabled(_ rule: Rule) -> Bool {
        return !isRuleDisabled(rule)
    }

    public func isRuleDisabled(_ rule: Rule) -> Bool {
        let identifiers = type(of: rule).description.allIdentifiers
        return !disabledRuleIdentifiers.intersection(identifiers).isEmpty
    }

    public func deprecatedAliasesDisabling(rule: Rule) -> Set<String> {
        let identifiers = type(of: rule).description.deprecatedAliases
        return disabledRuleIdentifiers.intersection(identifiers)
    }
}

// MARK: Equatable

public func == (lhs: Region, rhs: Region) -> Bool {
    return lhs.start == rhs.start &&
        lhs.end == rhs.end &&
        lhs.disabledRuleIdentifiers == rhs.disabledRuleIdentifiers
}
