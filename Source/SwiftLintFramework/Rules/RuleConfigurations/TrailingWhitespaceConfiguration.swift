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
        return severityConfiguration.consoleDescription +
            ", ignores_empty_lines: \(ignoresEmptyLines)"
    }

    public init(ignoresEmptyLines: Bool) {
        self.ignoresEmptyLines = ignoresEmptyLines
    }

    public mutating func applyConfiguration(_ configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        ignoresEmptyLines = (configuration["ignores_empty_lines"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: TrailingWhitespaceConfiguration,
                rhs: TrailingWhitespaceConfiguration) -> Bool {
    return lhs.ignoresEmptyLines == rhs.ignoresEmptyLines
}
