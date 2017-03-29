//
//  ImportsRuleConfiguration.swift
//  SwiftLint
//
//  Created by Miguel Revetria on 7/2/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct SortedImportsConfiguration: RuleConfiguration, Equatable {

    private(set) var ignoreCase: Bool
    private(set) var testableImportsPosition: TestableImportsPosition

    private(set) var severityConfiguration = SeverityConfiguration(.warning)

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", ignore_case: \(ignoreCase), testable_imports_position: \(testableImportsPosition)"
    }

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    public init(ignoreCase: Bool, testableImportsPosition: TestableImportsPosition) {
        self.ignoreCase = ignoreCase
        self.testableImportsPosition = testableImportsPosition
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        ignoreCase = (configuration["ignore_case"] as? Bool == true)
        testableImportsPosition = TestableImportsPosition(
            rawValue: configuration["testable_imports_position"] as? String ?? ""
        ) ?? .bottom

        if let severity = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severity)
        }
    }

}

public func == (lhs: SortedImportsConfiguration, rhs: SortedImportsConfiguration) -> Bool {
    return lhs.ignoreCase == rhs.ignoreCase &&
        lhs.testableImportsPosition == rhs.testableImportsPosition &&
        lhs.severityConfiguration == rhs.severityConfiguration
}
