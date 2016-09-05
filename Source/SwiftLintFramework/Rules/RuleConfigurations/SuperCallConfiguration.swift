//
//  SuperCallConfiguration.swift
//  SwiftLint
//
//  Created by Angel Garcia on 05/09/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SuperCallConfiguration: RuleConfiguration, Equatable {
    var defaultIncluded = [
        "viewWillAppear(_:)",
        "viewWillDisappear(_:)",
        "viewDidAppear(_:)",
        "viewDidDisappear(_:)",
        "prepareForSegue(_:sender:)"
    ]

    var severityConfiguration = SeverityConfiguration(.Warning)
    var excluded: [String] = []
    var included: [String] = ["*"]

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", excluded: [\(excluded)]" +
            ", included: [\(included)]"
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configuration = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }

        if let excluded = [String].arrayOf(configuration["excluded"]) {
            self.excluded = excluded
        }

        if let included = [String].arrayOf(configuration["included"]) {
            self.included = included
        }
    }

    
    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    public var resolvedMethodNames: [String] {
        var names: [String] = []
        if included.contains("*") && !excluded.contains("*") {
            names += defaultIncluded
        }
        names += included.filter({ $0 != "*" })
        names = names.filter { !excluded.contains($0) }
        return names
    }
}

public func == (lhs: SuperCallConfiguration,
                rhs: SuperCallConfiguration) -> Bool {
    return lhs.excluded == rhs.excluded &&
        lhs.included == rhs.included &&
        lhs.severityConfiguration == rhs.severityConfiguration
}
