//
//  YodaConditionConfiguration.swift
//  SwiftLint
//
//  Created by Daniel.Metzing on 02/12/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct YodaConditionConfiguration: RuleConfiguration, Equatable {

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public static func == (lhs: YodaConditionConfiguration,
                           rhs: YodaConditionConfiguration) -> Bool {
        return lhs.severityConfiguration == rhs.severityConfiguration
    }
}
