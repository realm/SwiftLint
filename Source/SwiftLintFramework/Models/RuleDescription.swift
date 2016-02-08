//
//  RuleDescription.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 25/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public struct RuleDescription: Equatable {
    public let identifier: String
    public let name: String
    public let description: String
    public let nonTriggeringExamples: [String]
    public let triggeringExamples: [String]
    public let corrections: [String: String]
    public let needsSourceKit: Bool

    public var consoleDescription: String { return "\(name) (\(identifier)): \(description)" }

    public init(identifier: String, name: String, description: String,
        nonTriggeringExamples: [String] = [], triggeringExamples: [String] = [],
        corrections: [String: String] = [:], needsSourceKit: Bool = true) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.nonTriggeringExamples = nonTriggeringExamples
        self.triggeringExamples = triggeringExamples
        self.corrections = corrections
        self.needsSourceKit = needsSourceKit
    }
}

// MARK: Equatable

public func == (lhs: RuleDescription, rhs: RuleDescription) -> Bool {
    return lhs.identifier == rhs.identifier
}
