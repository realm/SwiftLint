//
//  AttributesConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 26/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct AttributesConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.Warning)
    private(set) var alwaysInSameLine = Set<String>()
    private(set) var alwaysInNewLine = Set<String>()

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", always_in_same_line: \(alwaysInSameLine)" +
            ", always_in_new_line: \(alwaysInNewLine)"
    }

    public init(alwaysInSameLine: [String] = ["@IBAction", "@NSManaged"],
                alwaysInNewLine: [String] = []) {
        self.alwaysInSameLine = Set(alwaysInSameLine)
        self.alwaysInNewLine = Set(alwaysInNewLine)
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configuration = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let alwaysInSameLine = configuration["always_in_same_line"] as? [String] {
            self.alwaysInSameLine = Set(alwaysInSameLine)
        }

        if let alwaysInNewLine = configuration["always_in_new_line"] as? [String] {
            self.alwaysInNewLine = Set(alwaysInNewLine)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: AttributesConfiguration,
                rhs: AttributesConfiguration) -> Bool {
    return lhs.severityConfiguration == rhs.severityConfiguration &&
        lhs.alwaysInSameLine == rhs.alwaysInSameLine &&
        rhs.alwaysInNewLine == rhs.alwaysInNewLine
}
