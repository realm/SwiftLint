//
//  NumberSeparatorConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct NumberSeparatorConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var minimumLength: Int

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", minimum_length: \(minimumLength)"
    }

    public init(minimumLength: Int) {
        self.minimumLength = minimumLength
    }

    public mutating func applyConfiguration(_ configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        minimumLength = configuration["minimum_length"] as? Int ?? 0

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }

    public static func == (lhs: NumberSeparatorConfiguration,
                           rhs: NumberSeparatorConfiguration) -> Bool {
        return lhs.minimumLength == rhs.minimumLength &&
            lhs.severityConfiguration == rhs.severityConfiguration
    }
}
