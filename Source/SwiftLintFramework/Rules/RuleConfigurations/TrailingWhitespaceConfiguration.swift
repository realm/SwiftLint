//
//  TrailingWhitespaceConfiguration.swift
//  SwiftLint
//
//  Created by Reimar Twelker on 12.04.16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct TrailingWhitespaceConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.Warning)
    var ignoresEmptyLines = false

    public var consoleDescription: String {
        return "ignores_empty_lines: \(ignoresEmptyLines ? "true" : "false")"
    }

    public init(ignoresEmptyLines: Bool) {
        self.ignoresEmptyLines = ignoresEmptyLines
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configuration = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let ignoresEmptyLinesString = configuration["ignores_empty_lines"] as? String {
            ignoresEmptyLines = (ignoresEmptyLinesString == "true")
        } else {
            ignoresEmptyLines = false
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: TrailingWhitespaceConfiguration,
                rhs: TrailingWhitespaceConfiguration) -> Bool {
    return lhs.ignoresEmptyLines == rhs.ignoresEmptyLines
}
