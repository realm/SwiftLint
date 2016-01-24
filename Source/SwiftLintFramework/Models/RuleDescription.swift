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
    public let nonTriggeringExamples: [Trigger]
    public let triggeringExamples: [Trigger]
    public let corrections: [String: String]

    public var consoleDescription: String { return "\(name) (\(identifier)): \(description)" }

    public init(identifier: String, name: String, description: String,
        nonTriggeringExamples: [Trigger] = [], triggeringExamples: [Trigger] = [],
        corrections: [String: String] = [:]) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.nonTriggeringExamples = nonTriggeringExamples
        self.triggeringExamples = triggeringExamples
        self.corrections = corrections
    }
}

// MARK: Equatable

public func == (lhs: RuleDescription, rhs: RuleDescription) -> Bool {
    return lhs.identifier == rhs.identifier
}

public struct Trigger {
    public let string: String
    public let file: String
    public let line: UInt
    public init(_ string: String, file: String = __FILE__, line: Int = __LINE__) {
        self.string = string
        self.file = file
        self.line = UInt(line)
    }
}
