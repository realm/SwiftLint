//
//  EducatedSortingConfiguration.swift
//  SwiftLint
//
//  Created by Jamie Edge on 23/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct EducatedSortingConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var threshold: Float

    public var consoleDescription: String {
        return ""
    }

    public init(threshold: Float = 0.2) {
        self.threshold = threshold
    }

    public mutating func applyConfiguration(_ configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let threshold = configuration["threshold"] as? Float {
            self.threshold = threshold
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: EducatedSortingConfiguration, rhs: EducatedSortingConfiguration) -> Bool {
    return lhs.threshold == rhs.threshold &&
        lhs.severityConfiguration == rhs.severityConfiguration
}
