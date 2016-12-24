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
    private(set) var minimumItems: Int
    private(set) var caseSensitive: Bool

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", threshold: \(threshold)" +
            ", minimum_items: \(minimumItems)" +
            ", case_sensitive: \(caseSensitive)"
    }

    public init(threshold: Float = 0.25, minimumItems: Int = 3, caseSensitive: Bool = true) {
        self.threshold = threshold
        self.minimumItems = minimumItems
        self.caseSensitive = caseSensitive
    }

    public mutating func applyConfiguration(_ configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let threshold = configuration["threshold"] as? Float {
            self.threshold = threshold
        }

        if let minimumItems = configuration["min_items"] as? Int {
            self.minimumItems = minimumItems
        }

        if let caseSensitive = configuration["case_sensitive"] as? Bool {
            self.caseSensitive = caseSensitive
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: EducatedSortingConfiguration, rhs: EducatedSortingConfiguration) -> Bool {
    return lhs.severityConfiguration == rhs.severityConfiguration &&
        lhs.threshold == rhs.threshold &&
        lhs.minimumItems == rhs.minimumItems &&
        lhs.caseSensitive == rhs.caseSensitive
}
