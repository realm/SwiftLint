//
//  NumberSeparatorConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/02/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct NumberSeparatorConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var minimumLength: Int

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", minimum_length: \(minimumLength)"
    }

    public init(minimumLength: Int) {
        self.minimumLength = minimumLength
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let minimumLength = configuration["minimum_length"] as? Int {
            self.minimumLength = minimumLength
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public static func == (lhs: NumberSeparatorConfiguration,
                           rhs: NumberSeparatorConfiguration) -> Bool {
        return lhs.minimumLength == rhs.minimumLength &&
            lhs.severityConfiguration == rhs.severityConfiguration
    }
}
