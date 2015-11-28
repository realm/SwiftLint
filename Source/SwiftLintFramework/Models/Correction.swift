//
//  Correction.swift
//  SwiftLint
//
//  Created by JP Simard on 11/27/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public struct Correction {
    public let ruleDescription: RuleDescription
    public let location: Location

    public var consoleDescription: String {
        return "\(location) Corrected \(ruleDescription.name)"
    }
}
