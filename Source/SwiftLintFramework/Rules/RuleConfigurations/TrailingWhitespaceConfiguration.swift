//
//  TrailingWhitespaceConfiguration.swift
//  SwiftLint
//
//  Created by Reimar Twelker on 12/4/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct TrailingWhitespaceConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var ignoresEmptyLines = false
    var ignoresComments = true

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", ignores_empty_lines: \(ignoresEmptyLines)" +
            ", ignores_comments: \(ignoresComments)"
    }

    public init(ignoresEmptyLines: Bool, ignoresComments: Bool) {
        self.ignoresEmptyLines = ignoresEmptyLines
        self.ignoresComments = ignoresComments
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        ignoresEmptyLines = (configuration["ignores_empty_lines"] as? Bool == true)
        ignoresComments = (configuration["ignores_comments"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}

public func == (lhs: TrailingWhitespaceConfiguration,
                rhs: TrailingWhitespaceConfiguration) -> Bool {
    return lhs.ignoresEmptyLines == rhs.ignoresEmptyLines &&
        lhs.ignoresComments == rhs.ignoresComments &&
        lhs.severityConfiguration == rhs.severityConfiguration
}
